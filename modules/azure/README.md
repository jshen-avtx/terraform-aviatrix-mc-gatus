# terraform-aviatrix-mc-gatus

## Description

Deploys a `VNET` and [Gatus](https://github.com/TwiN/gatus) workload instances across one to three AZs generating traffic to configured destinations/protocols.

All deployed instances conform to the following spec:

| Cloud     | Ubuntu Version | Additionally installed Software | Instance size      |
| :-------- | :------------- | :------------------------------ | :----------------- |
| **Azure** | `24.04`        | `Docker`, `Gatus`               | `Standard_B2ts_v2` |

## Diagram

<img src="https://github.com/terraform-aviatrix-modules/terraform-aviatrix-mc-gatus/blob/main/img/azure.png?raw=true">

## Resources required

Ensure your CSP quotas allow for the creation of the following resources.

### Azure

| Resource     | Number | Default |
| :----------- | :----- | :------ |
| Public IPs   | 1 to 2 | 2       |
| Vnets        | 1      | 1       |
| NAT Gateways | 1      | 1       |
| vCPUs        | 4 to 8 | 6       |

## Compatibility

| Module version | Terraform version | Terraform provider version (Azure) |
| :------------- | :---------------- | :--------------------------------- |
| v0.9.1         | >= 1.9.8          | >= 4.26.0                          |

## Usage Examples

The following examples offer snippets of code for calling the module(s). See [examples](https://github.com/terraform-aviatrix-modules/terraform-aviatrix-mc-gatus/tree/main/examples) for full ready to execute code (personalization required).

### Azure

```terraform
module "mc_gatus" {
  source       = "terraform-aviatrix-modules/mc-gatus/aviatrix//modules/azure"
  version      = "0.9.1"
  azure_region = var.azure_region
}
output "azure_dashboard" {
  value = module.mc_gatus.azure_dashboard_public_ip != null ? "http://${module.mc_gatus.azure_dashboard_public_ip}" : null
}
```

## Input Variables

### Required

The following input variables are required:

<img src="https://github.com/terraform-aviatrix-modules/terraform-aviatrix-mc-transit/blob/main/img/aws.png?raw=true" title="AWS"> = AWS, <img src="https://github.com/terraform-aviatrix-modules/terraform-aviatrix-mc-transit/blob/main/img/azure.png?raw=true" title="Azure"> = Azure,

#### Azure submodule

| Name                                                                     | Description   | Supported CSPs                                                                                                                         | Type     | Default | Required |
| ------------------------------------------------------------------------ | ------------- | -------------------------------------------------------------------------------------------------------------------------------------- | -------- | ------- | :------: |
| <a name="input_azure_region"></a> [azure\_region](#input\_azure\_region) | Azure region. | <img src="https://github.com/terraform-aviatrix-modules/terraform-aviatrix-mc-transit/blob/main/img/azure.png?raw=true" title="Azure"> | `string` | `null`  |   yes    |

### Optional

The following input variables are optional:

<img src="https://github.com/terraform-aviatrix-modules/terraform-aviatrix-mc-transit/blob/main/img/aws.png?raw=true" title="AWS"> = AWS, <img src="https://github.com/terraform-aviatrix-modules/terraform-aviatrix-mc-transit/blob/main/img/azure.png?raw=true" title="Azure"> = Azure, 

| Name                                                                                                             | Description                                                    | Supported CSPs                                                                                                                                                                                                                                                            | Type                | Default                                                                                                                                                                                                                                                                                                                                                                                                                                                       | Required |
| ---------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :------: |
| <a name="input_name_prefix"></a> [name_prefix](#input\_name_prefix)                                              | Prefix to apply to all resources(s).                           | <img src="https://github.com/terraform-aviatrix-modules/terraform-aviatrix-mc-transit/blob/main/img/aws.png?raw=true" title="AWS"> <img src="https://github.com/terraform-aviatrix-modules/terraform-aviatrix-mc-transit/blob/main/img/azure.png?raw=true" title="Azure"> | `string`            | `mc-gatus`                                                                                                                                                                                                                                                                                                                                                                                                                                                    |    no    |
| <a name="input_azure_cidr"></a> [azure\_cidr](#input\_azure\_cidr)                                               | Azure vpc cidr.                                                | <img src="https://github.com/terraform-aviatrix-modules/terraform-aviatrix-mc-transit/blob/main/img/azure.png?raw=true" title="Azure">                                                                                                                                    | `string`            | `"10.2.0.0/24"`                                                                                                                                                                                                                                                                                                                                                                                                                                               |    no    |
| <a name="input_azure_instance_type"></a> [azure\_instance\_type](#input\_azure\_instance\_type)                  | Instance type for the azure instances.                         | <img src="https://github.com/terraform-aviatrix-modules/terraform-aviatrix-mc-transit/blob/main/img/azure.png?raw=true" title="Azure">                                                                                                                                    | `string`            | `Standard_B2ts_v2`                                                                                                                                                                                                                                                                                                                                                                                                                                            |    no    |
| <a name="input_dashboard"></a> [dashboard](#input\_dashboard)                                                    | Create a dashboard to expose gatus status to the Internet.     | <img src="https://github.com/terraform-aviatrix-modules/terraform-aviatrix-mc-transit/blob/main/img/aws.png?raw=true" title="AWS"> <img src="https://github.com/terraform-aviatrix-modules/terraform-aviatrix-mc-transit/blob/main/img/azure.png?raw=true" title="Azure"> | `bool`              | `true`                                                                                                                                                                                                                                                                                                                                                                                                                                                        |    no    |
| <a name="input_dashboard_access_cidr"></a> [dashboard\_access\_cidr](#input\_dashboard\_access\_cidr)            | CIDR that has http access to the dashboard(s).                 | <img src="https://github.com/terraform-aviatrix-modules/terraform-aviatrix-mc-transit/blob/main/img/aws.png?raw=true" title="AWS"> <img src="https://github.com/terraform-aviatrix-modules/terraform-aviatrix-mc-transit/blob/main/img/azure.png?raw=true" title="Azure"> | `string`            | Internet source IP of the executing system                                                                                                                                                                                                                                                                                                                                                                                                                    |    no    |
| <a name="input_dashboard_user"></a> [dashboard\_user](#input\_dashboard\_user)                                   | User login for the dashboard.                                  | <img src="https://github.com/terraform-aviatrix-modules/terraform-aviatrix-mc-transit/blob/main/img/aws.png?raw=true" title="AWS"> <img src="https://github.com/terraform-aviatrix-modules/terraform-aviatrix-mc-transit/blob/main/img/azure.png?raw=true" title="Azure"> | `string`            | `null`                                                                                                                                                                                                                                                                                                                                                                                                                                                        |    no    |
| <a name="input_dashboard_password"></a> [dashboard\_password](#input\_dashboard\_password)                       | User password for the dashboard.                               | <img src="https://github.com/terraform-aviatrix-modules/terraform-aviatrix-mc-transit/blob/main/img/aws.png?raw=true" title="AWS"> <img src="https://github.com/terraform-aviatrix-modules/terraform-aviatrix-mc-transit/blob/main/img/azure.png?raw=true" title="Azure"> | `string`            | `null`                                                                                                                                                                                                                                                                                                                                                                                                                                                        |    no    |
| <a name="input_dashboard_certificate"></a> [dashboard\_certificate](#input\_dashboard\_certificate)              | Certificate for the dashboard.                                 | <img src="https://github.com/terraform-aviatrix-modules/terraform-aviatrix-mc-transit/blob/main/img/aws.png?raw=true" title="AWS"> <img src="https://github.com/terraform-aviatrix-modules/terraform-aviatrix-mc-transit/blob/main/img/azure.png?raw=true" title="Azure"> | `string`            | `null`                                                                                                                                                                                                                                                                                                                                                                                                                                                        |    no    |
| <a name="input_dashboard_certificate_key"></a> [dashboard\_certificate\_key](#input\_dashboard\_certificate_key) | Certificate key for the dashboard.                             | <img src="https://github.com/terraform-aviatrix-modules/terraform-aviatrix-mc-transit/blob/main/img/aws.png?raw=true" title="AWS"> <img src="https://github.com/terraform-aviatrix-modules/terraform-aviatrix-mc-transit/blob/main/img/azure.png?raw=true" title="Azure"> | `string`            | `null`                                                                                                                                                                                                                                                                                                                                                                                                                                                        |    no    |
| <a name="input_dashboard_ssh_key"></a> [dashboard\_ssh\_key](#input\_dashboard\_ssh_key)                         | SSH key for the dashboard.                                     | <img src="https://github.com/terraform-aviatrix-modules/terraform-aviatrix-mc-transit/blob/main/img/aws.png?raw=true" title="AWS"> <img src="https://github.com/terraform-aviatrix-modules/terraform-aviatrix-mc-transit/blob/main/img/azure.png?raw=true" title="Azure"> | `string`            | `null`                                                                                                                                                                                                                                                                                                                                                                                                                                                        |    no    |
| <a name="input_gatus_endpoints"></a> [gatus\_endpoints](#input\_gatus\_endpoints)                                | Gatus endpoints to test.                                       | <img src="https://github.com/terraform-aviatrix-modules/terraform-aviatrix-mc-transit/blob/main/img/aws.png?raw=true" title="AWS"> <img src="https://github.com/terraform-aviatrix-modules/terraform-aviatrix-mc-transit/blob/main/img/azure.png?raw=true" title="Azure"> | `map(list(string))` | <pre>{<br/>  "http": [<br/>    "de.vu",<br/>    "69298.com",<br/>    "tiktock.com",<br/>    "acrilhacrancon.com",<br/>    "blockexplorer.com"<br/>  ],<br/>  "https": [<br/>    "aviatrix.com",<br/>    "aws.amazon.com",<br/>    "www.microsoft.com",<br/>    "cloud.google.com",<br/>    "github.com",<br/>    "thishabboforum.com",<br/>    "malware.net",<br/>    "go.dev",<br/>    "dk-metall.ru"<br/>  ],<br/>  "icmp": [],<br/>  "tcp": []<br/>}</pre> |    no    |
| <a name="input_gatus_interval"></a> [gatus\_interval](#input\_gatus\_interval)                                   | Gatus polling interval.                                        | <img src="https://github.com/terraform-aviatrix-modules/terraform-aviatrix-mc-transit/blob/main/img/aws.png?raw=true" title="AWS"> <img src="https://github.com/terraform-aviatrix-modules/terraform-aviatrix-mc-transit/blob/main/img/azure.png?raw=true" title="Azure"> | `number`            | `10`                                                                                                                                                                                                                                                                                                                                                                                                                                                          |    no    |
| <a name="input_gatus_version"></a> [gatus\_version](#input\_gatus\_version)                                      | Gatus version.                                                 | <img src="https://github.com/terraform-aviatrix-modules/terraform-aviatrix-mc-transit/blob/main/img/aws.png?raw=true" title="AWS"> <img src="https://github.com/terraform-aviatrix-modules/terraform-aviatrix-mc-transit/blob/main/img/azure.png?raw=true" title="Azure"> | `string`            | `"5.12.1"`                                                                                                                                                                                                                                                                                                                                                                                                                                                    |    no    |
| <a name="input_local_user"></a> [local\_user](#input\_local\_user)                                               | Local user to create on the gatus instances.                   | <img src="https://github.com/terraform-aviatrix-modules/terraform-aviatrix-mc-transit/blob/main/img/aws.png?raw=true" title="AWS"> <img src="https://github.com/terraform-aviatrix-modules/terraform-aviatrix-mc-transit/blob/main/img/azure.png?raw=true" title="Azure"> | `string`            | `"gatus"`                                                                                                                                                                                                                                                                                                                                                                                                                                                     |    no    |
| <a name="input_local_user_password"></a> [local\_user\_password](#input\_local\_user\_password)                  | Password for the local user on the gatus instances.            | <img src="https://github.com/terraform-aviatrix-modules/terraform-aviatrix-mc-transit/blob/main/img/aws.png?raw=true" title="AWS"> <img src="https://github.com/terraform-aviatrix-modules/terraform-aviatrix-mc-transit/blob/main/img/azure.png?raw=true" title="Azure"> | `string`            | `null`                                                                                                                                                                                                                                                                                                                                                                                                                                                        |    no    |
| <a name="input_number_of_instances"></a> [number\_of\_instances](#input\_number\_of\_instances)                  | Number of gatus instances spread across subnets/azs to create. | <img src="https://github.com/terraform-aviatrix-modules/terraform-aviatrix-mc-transit/blob/main/img/aws.png?raw=true" title="AWS"> <img src="https://github.com/terraform-aviatrix-modules/terraform-aviatrix-mc-transit/blob/main/img/azure.png?raw=true" title="Azure"> | `number`            | `2`                                                                                                                                                                                                                                                                                                                                                                                                                                                           |    no    |

## Outputs

| Name                                                                                                                  | Description                                                              |
| --------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------ |
| <a name="output_azure_dashboard_public_ip"></a> [azure\_dashboard\_public\_ip](#output\_azure\_dashboard\_public\_ip) | Azure Gatus Dashboard Public IP.                                         |
| <a name="output_azure_gateway_subnet"></a> [azure\_gateway\_subnet](#output\_azure\_gateway\_subnet)                  | The Azure gateway subnet ID and address prefixes.                        |
| <a name="output_azure_local_user_password"></a> [azure\_local\_user\_password](#output\_local\_user\_password)        | The generated azure random local\_user\_password if not provided.        |
| <a name="output_azure_vnet"></a> [azure\_vnet](#output\_azure_vnet)                                                   | The Azure VNet resource ID and name (`resource_id`, `name`).             |

## Running Tests

Unit tests use `mock_provider` — no Azure credentials or real resources required.

```bash
cd modules/azure
terraform init
terraform test
```

The test suite covers variable validation (16 runs), default behavior (5 runs), and conditional resource creation (5 runs). All runs use `command = plan`.
