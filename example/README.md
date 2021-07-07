# Example usage

First you will need to have a TFC organization,
and credentials set via `terraform login`.

And AWS credentials in your environment.

## Setup

* Edit `var.tfc_org` and `terraform{ backend{ <<org>> } }`

  as appropriate to match your TFC organization.

* `terraform init`
  will fail first time, but fret not!

* `terraform workspace new dev`
  creates a workspace in TFC.

* Edit settings in "tfc-agents-dev" workspace in TFC

  Settings -> General -> Execution Mode -> Local

  and Remote state sharing -> Share state globally

* `terraform init` again to pull modules

## Run

```shell
# if this command does not work, set your TFE_TOKEN manually.
export TFE_TOKEN="$(jq -r '.credentials."app.terraform.io".token' ~/.terraform.d/credentials.tfrc.json)"

terraform apply
```
