# terraform-module-template
Template for Terraform modules

<!-- Uncomment and replace with your module name
[![lint](https://github.com/flaconi/<MODULENAME>/workflows/lint/badge.svg)](https://github.com/flaconi/<MODULENAME>/actions?query=workflow%3Alint)
[![test](https://github.com/flaconi/<MODULENAME>/workflows/test/badge.svg)](https://github.com/flaconi/<MODULENAME>/actions?query=workflow%3Atest)
[![Tag](https://img.shields.io/github/tag/flaconi/<MODULENAME>.svg)](https://github.com/flaconi/<MODULENAME>/releases)
-->
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

For requirements regarding module structure: [style-guide-terraform.md](https://github.com/Flaconi/devops-docs/blob/master/doc/conventions/style-guide-terraform.md)

<!-- TFDOCS_HEADER_START -->


<!-- TFDOCS_HEADER_END -->

<!-- TFDOCS_PROVIDER_START -->
## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

<!-- TFDOCS_PROVIDER_END -->

<!-- TFDOCS_REQUIREMENTS_START -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.3 |

<!-- TFDOCS_REQUIREMENTS_END -->

<!-- TFDOCS_INPUTS_START -->
## Required Inputs

The following input variables are required:

### <a name="input_slack_team_name"></a> [slack\_team\_name](#input\_slack\_team\_name)

Description: Name of slack workspace

Type: `string`

### <a name="input_source_account"></a> [source\_account](#input\_source\_account)

Description: The AWS account ID of the account that will be sending the cost alerts

Type: `string`

### <a name="input_alert_config"></a> [alert\_config](#input\_alert\_config)

Description: n/a

Type:

```hcl
map(object({
    sns_topic_name = string
    cost_monitor = object({
      monitor_type = string #ONLY ONE DIMENSIONAL otherwise custom
      name         = optional(string)
    })
    subscriptions = list(object({
      monitor_names    = optional(list(string), []) # additional monitors beside the existing one
      frequency        = string                     #DAILY, IMMEDIATE, WEEKLY
      slack_channel_id = optional(string)
      name             = string
      subscriber       = optional(list(string), []) #EMAILS sns arn is added automatically
      threshold_expresion = object({
        key          = string
        match_option = string
        value        = string
      })
    }))
  }))
```

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_tags"></a> [tags](#input\_tags)

Description: A map of tags to assign to the resources

Type: `map(string)`

Default: `null`

<!-- TFDOCS_INPUTS_END -->

<!-- TFDOCS_OUTPUTS_START -->
## Outputs

No outputs.

<!-- TFDOCS_OUTPUTS_END -->

## License

**[MIT License](LICENSE)**

Copyright (c) 2023 **[Flaconi GmbH](https://github.com/flaconi)**
