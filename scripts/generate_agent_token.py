#!/usr/bin/env python
import logging
import os
from time import time

import boto3
import logzero
from botocore.exceptions import ClientError
from logzero import logger
from terrasnek.api import TFC

DEFAULT_AWS_REGION = os.getenv("AWS_REGION", "us-west-2")
DEFAULT_TFC_URL = "https://app.terraform.io"
DEFAULT_ORG = "hc-common-release-tooling-vault"
OWNER_MAILING_LIST = "team-engserv-vault+tfc@hashicorp.com"


def get_agent_pool_id(tfc_client, agent_pool_name, ensure_pool=False):
    # TODO: worry about pagination in the list_pools response?
    list_pools_resp = tfc_client.agents.list_pools()

    agent_pools_by_name = {p["attributes"]["name"]: p for p in list_pools_resp["data"]}

    if agent_pool_name in agent_pools_by_name:
        logger.debug(f"Found extant agent pool with name: {agent_pool_name}")
        return agent_pools_by_name[agent_pool_name]["id"]

    if ensure_pool:
        logger.debug(f"Creating agent pool with name: {agent_pool_name}")
        create_pool_resp = tfc_client.agents.create_pool(
            payload={
                "data": {
                    "type": "agent-pools",
                    "attributes": {"name": agent_pool_name},
                }
            }
        )
        logger.debug(f"{create_pool_resp=}")
        return create_pool_resp["data"]["id"]
    raise Exception(
        f"Unable to find agent pool '{agent_pool_name}' (and {ensure_pool=})"
    )


def write_token_to_ssm(ssm_client, name, description, new_token):
    put_param_kwargs = dict(
        Name=name,
        Type="SecureString",
        Value=new_token,
        Description=description,
    )
    logger.info(f"Checking if a parameter with name '{name}' already exists...")
    try:
        get_param_resp = ssm_client.get_parameter(
            Name=name,
        )
        logger.debug(f'{get_param_resp=}')
    except ClientError as err:
        logger.debug(f'SSM param "{name}" has not yet been created! ({err})')
        # > botocore.exceptions.ClientError: An error occurred (ValidationException) when calling the PutParameter operation:
        # >  Invalid request: tags and overwrite can't be used together.
        # >  To create a parameter with tags, please remove overwrite flag.
        # >  To update tags for an existing parameter, please use AddTagsToResource or RemoveTagsFromResource.
        put_param_kwargs['Tags'] = [
            {"Key": "hc-owner", "Value": OWNER_MAILING_LIST},
            {"Key": "hc-config-as-code", "Value": "no-config-as-code"},
        ]
    else:
        logger.debug(f'Extant SSM param "{name}" found!')
        # > botocore.errorfactory.ParameterAlreadyExists:
        # >   An error occurred (ParameterAlreadyExists) when calling the PutParameter operation:
        # >     The parameter already exists. To overwrite this value, set the overwrite option in the request to true.
        put_param_kwargs['Overwrite'] = True

    logger.info(f"Writing new token to parameter name: {name}")
    put_param_resp = ssm_client.put_parameter(**put_param_kwargs)
    logger.debug(f"{put_param_resp=}")


def tidy_agent_tokens(tfc_client, agent_pool_id, new_token_id):
    agent_tokens = tfc_client.agent_tokens.list(agent_pool_id=agent_pool_id)
    logger.debug(f"{agent_tokens}")
    raise NotImplementedError(
        "We could potentially tidy up some tokens here but such things are not currently implemented :)"
    )


def generate_agent_token(
    tfc_org, agent_pool_name, ssm_parameter_name, ensure_pool=False
):
    tfc_url = os.getenv("TFC_URL", DEFAULT_TFC_URL)
    tfc_client = TFC(
        api_token=os.getenv("TFE_TOKEN", None),
        url=tfc_url,
    )
    tfc_client.set_org(tfc_org)

    agent_pool_id = get_agent_pool_id(
        tfc_client=tfc_client,
        agent_pool_name=agent_pool_name,
        ensure_pool=ensure_pool,
    )
    logger.debug(f'Found agent pool ID "{agent_pool_id}" for {agent_pool_name}')

    logger.info(f"Creating new token under {agent_pool_name}")
    new_token_resp = tfc_client.agent_tokens.create(
        agent_pool_id=agent_pool_id,
        payload={
            "data": {
                "type": "authentication-tokens",
                "attributes": {"description": f"ecs-agents_{int(time())}"},
            }
        },
    )
    new_token_id = new_token_resp["data"]["id"]
    logger.info(f"New token ID: {new_token_id}")

    ssm_client = boto3.client(
        service_name="ssm",
        region_name=DEFAULT_AWS_REGION,
    )
    write_token_to_ssm(
        ssm_client=ssm_client,
        name=ssm_parameter_name,
        description=f"TFC Agent Token for hc-centralised-dns Pool in {tfc_url}/app/{tfc_org}/settings/agents",
        new_token=new_token_resp["data"]["attributes"]["token"],
    )
    print(
        "Agent pool token generation complete, set `TF_VAR_tfc_agent_token_param_name` in your environment to:"
    )
    print(ssm_parameter_name)

    try:
        tidy_agent_tokens(
            tfc_client=tfc_client,
            agent_pool_id=agent_pool_id,
            new_token_id=new_token_id,
        )
    except Exception as err:
        logger.error(err)


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(
        prog="TFC agent pool token generate and SSM parameter shover!"
    )
    parser.add_argument(
        "-v",
        "--verbose",
        help="modify output verbosity",
        action="store_true",
    )
    parser.add_argument(
        "-O",
        "--tfc-org",
        default=DEFAULT_ORG,
    )
    parser.add_argument(
        "-E",
        "--ensure-pool",
        help="Create the specified agent pool if not already extant.",
        action="store_true",
    )
    parser.add_argument(
        "-n",
        "--ssm-parameter-name",
        default="/tfc-agent/app.terraform.io/hc-common-release-tooling-vault/tfc-agent",
    )
    parser.add_argument(
        "-p",
        "--agent-pool-name",
        required=True,
    )
    args = parser.parse_args()

    if not args.verbose:
        logzero.loglevel(logging.INFO)

    generate_agent_token(
        tfc_org=args.tfc_org,
        agent_pool_name=args.agent_pool_name,
        ssm_parameter_name=args.ssm_parameter_name,
        ensure_pool=args.ensure_pool,
    )
