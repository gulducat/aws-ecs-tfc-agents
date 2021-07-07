# AWS ECS Terraform Cloud Agents

Private Terraform Cloud agents hosted in AWS ECS.

After initial setup, this allows Terraform TFC runs
to manage resources at AWS with no static credentials.

## Directories

### root

This module creates:

* TFC agent pool
* TFC workspace that uses it
* ECS cluster that runs our `tfc-agent`s

### example

contains an example of its usage,
including a custom AWS IAM role to be assumed by agents.

### example/test

uses the created workspace to test the agent pool
by assuming the role and outputting its identity.
