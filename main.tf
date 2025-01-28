locals {
  sns_topics = { for key, config in var.alert_config :
  key => config.sns_topic_name }

  subscribers = merge([for key, config in var.alert_config : {
    for subKey, subConfig in config.subscriptions :
  "${key}-${subConfig.name}" => merge(subConfig, { defaultMonitor = key }) }]...)

  slack = merge([for key, config in var.alert_config : {
    for subKey, subConfig in config.subscriptions :
    "${key}-${subConfig.name}" => merge(subConfig, { defaultMonitor = key })
    if subConfig.frequency == "IMMEDIATE"
    }
  ]...)
}

resource "aws_chatbot_slack_channel_configuration" "chatbot_slack_channel" {
  for_each              = local.slack
  configuration_name    = replace(each.value.name, " ", "-")
  slack_channel_id      = each.value.slack_channel_id
  slack_team_id         = data.aws_chatbot_slack_workspace.flaconi.slack_team_id
  sns_topic_arns        = [module.sns_topic.wrapper[each.value.defaultMonitor].topic_arn]
  iam_role_arn          = module.chatbot_role.iam_role_arn
  guardrail_policy_arns = ["arn:aws:iam::aws:policy/ReadOnlyAccess"]
  tags                  = var.tags

}

data "aws_iam_policy_document" "chatbot_notifications_only" {
  statement {
    actions = [
      "cloudwatch:Describe*",
      "cloudwatch:Get*",
      "cloudwatch:List*"
    ]
    resources = ["*"]
  }
}

module "chatbot_role_policy" {
  source = "github.com/terraform-aws-modules/terraform-aws-iam//modules/iam-policy?ref=v5.52.2"

  name        = "aws-chatbot-notifications-only-policy"
  path        = "/service-role/"
  description = "NotificationsOnly policy for AWS-Chatbot"

  policy = data.aws_iam_policy_document.chatbot_notifications_only.json

  tags = var.tags
}

module "chatbot_role" {
  source = "github.com/terraform-aws-modules/terraform-aws-iam//modules/iam-assumable-role?ref=v5.52.2"

  create_role = true

  role_requires_mfa      = false
  allow_self_assume_role = false

  role_path = "/service-role/"
  role_name = "aws-chatbot-role"

  trusted_role_actions = ["sts:AssumeRole"]

  trusted_role_services = [
    "chatbot.amazonaws.com"
  ]

  custom_role_policy_arns = [
    module.chatbot_role_policy.arn
  ]

  tags = var.tags
}

resource "aws_ce_anomaly_subscription" "subscriptions" {
  for_each         = local.subscribers
  name             = each.value.name
  frequency        = each.value.frequency
  monitor_arn_list = [aws_ce_anomaly_monitor.monitors[each.value.defaultMonitor].arn]

  dynamic "subscriber" {
    for_each = each.value.frequency == "IMMEDIATE" ? [true] : []
    content {
      type    = "SNS"
      address = module.sns_topic.wrapper[each.value.defaultMonitor].topic_arn
    }
  }

  dynamic "subscriber" {
    for_each = each.value.subscriber
    content {
      type    = strcontains(subscriber.value, "@") ? "EMAIL" : "SNS"
      address = subscriber.value
    }
  }

  threshold_expression {
    dimension {
      key           = each.value.threshold_expresion.key
      match_options = [each.value.threshold_expresion.match_option]
      values        = [each.value.threshold_expresion.value]
    }
  }

  tags = var.tags
}

resource "aws_ce_anomaly_monitor" "monitors" {
  for_each = var.alert_config

  name              = try(each.value.cost_monitor.name, each.key)
  monitor_type      = each.value.cost_monitor.monitor_type
  monitor_dimension = each.value.cost_monitor.monitor_type == "DIMENSIONAL" ? "SERVICE" : null
  tags              = var.tags
  monitor_specification = each.value.cost_monitor.monitor_type == "CUSTOM" ? jsonencode({
    And            = null
    CostCategories = null
    Dimensions     = null
    Not            = null
    Or             = null

    Tags = {
      Key          = "CostCenter"
      MatchOptions = null
      Values = [
        "10000"
      ]
    }
  }) : null
}

module "sns_topic" {
  source = "github.com/terraform-aws-modules/terraform-aws-sns//wrappers?ref=v6.1.2"

  defaults = {
    tags                        = var.tags
    enable_default_topic_policy = false
  }
  items = { for key, sns_topic in local.sns_topics :
    key => {
      name = sns_topic
      topic_policy_statements = {
        cost_publish = {
          actions = ["sns:Publish"]
          principals = [{
            type        = "Service"
            identifiers = ["costalerts.amazonaws.com"]
          }]
          conditions = [{
            test     = "StringEquals"
            variable = "aws:SourceAccount"
            values   = [var.source_account]
          }]
        }
      }
    }
  }
}
