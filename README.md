# TFC Agent (running in ECS)

TFC remote agent infrastructure for the [`hc-common-release-tooling-vault` TFC organization](https://app.terraform.io/app/hc-common-release-tooling-vault).

What follows is a derivation of [hc-centralized-dns](https://github.com/hashicorp/hc-centralized-dns/tree/main/tfc/agent)'s derivation of Andy Assareh's
[TFC Agent on ECS](https://github.com/assareh/tfc-agent) configuration.  It's
deployed into an isolated Security Group, with no inbound connections, on a
private VPC (behind a NAT).  The Task has attached permissions necessary to
manipulate Route53 Zones and Records.  This allows us to avoid populating static
credentials into TFC

## Performing Updates

Updates are handled through VCS-initated TFC runs within the `tfc-agents-`-prefix workspaces under the `hc-common-release-tooling-vault` TFC organization: [link](https://app.terraform.io/app/hc-common-release-tooling-vault/workspaces?search=tfc-agents-).

**Note**: Initial provisioning of a new environment / account requires some locally-executed bootstrapping. For this scenario, the subsequent "Development" steps must be used for the initial Terraform runs (and subsequent changes can _then_ be managed via TFC workspace).

## Bootstrapping / Development

Here are the steps to deploy this TFC agent on ECS configuration from scratch (for development purposes, new environments, etc.):

1. Start a doormat credential server locally (and leave it running): `bash -c 'doormat --smoke-test || doormat --refresh' && doormat aws cred-server`
1. Set an environment variable to inform AWS SDK's / the credential server which account you're addressing. E.g.: `export AWS_CONTAINER_CREDENTIALS_FULL_URI="http://127.0.0.1:9000/role/engserv_vault_dev"` (**Note**: This variable should exported in the same shell session as the subsequent `generate_agent_token.py` and `terraform` innvocation).
1. Create an agent pool and generate a token under it via the adjacent `generate_agent_token.py` script (this can be also done via the TFC UI + AWS CLI where desired):

    ```shellsession
    %▶ ./scripts/generate_agent_token.py --ensure-pool --agent-pool-name=jhog-test
    [I 210615 10:41:57 generate_agent_token:107] Creating new token under jhog-test
    [I 210615 10:41:58 generate_agent_token:118] New token ID: at-nqqFmEA1dyMbyut6
    [I 210615 10:41:58 generate_agent_token:54] Checking if a parameter with name '/tfc-agent/app.terraform.io/hc-common-release-tooling-vault/jhog-test' already exists...
    [I 210615 10:41:58 generate_agent_token:77] Writing new token to parameter name: /tfc-agent/app.terraform.io/hc-common-release-tooling-vault/jhog-test
    Agent pool token generation complete, set `TF_VAR_tfc_agent_token_param_name` in your environment to:
    /tfc-agent/app.terraform.io/hc-common-release-tooling-vault/jhog-test
    [E 210615 10:41:59 generate_agent_token:143] We could potentially tidy up some tokens here but such things are not currently implemented :)
    ```

1. Apply the associated Terraform `terraform init && terraform apply`
1. Check the [agent pool section of the associated TFC organization](https://app.terraform.io/app/hc-common-release-tooling-vault/settings/agents?page=1) and ensure your pool now has an agent spun up in it. **Note**: It may take the task some time to transition from "pending" to "active"; you can check on the [ECS task in the AWS console](https://us-west-2.console.aws.amazon.com/ecs/home) to validate the task's state.
1. Set a test workspace or such to use the agent pool you provisioned: workspace -> settings -> execution mode -> agent pool

### generate_agent_token.py Env Setup

```shellsession
# mkvirtualenv => https://virtualenvwrapper.readthedocs.io/en/latest/
%▶ mkvirtualenv -a $PWD crt-vault
created virtual environment CPython3.8.2.final.0-64 in 3448ms
  creator CPython3Posix(dest=/Users/jeffwecan/.virtualenvs/crt-vault, clear=False, global=False)
  seeder FromAppData(download=True, pip=latest, setuptools=latest, wheel=latest, via=copy, app_data_dir=/Users/jeffwecan/Library/Application Support/virtualenv/seed-app-data/v1.0.1)
  activators BashActivator,CShellActivator,FishActivator,PowerShellActivator,PythonActivator,XonshActivator
Setting project for crt-vault to /Users/jeffwecan/workspace/crt-vault-experiments
%▶ pip install pip-tools
Collecting pip-tools
[...]
Installing collected packages: toml, pep517, click, pip-tools
Successfully installed click-8.0.1 pep517-0.10.0 pip-tools-6.1.0 toml-0.10.2
%▶ cd tfc/agent/scripts
%▶ pip-compile --output-file=requirements.txt requirements.in
%▶ pip install --requirement=requirements.txt
[...]
Installing collected packages: six, urllib3, python-dateutil, jmespath, idna, chardet, certifi, botocore, s3transfer, requests, terrasnek, logzero, boto3
```
