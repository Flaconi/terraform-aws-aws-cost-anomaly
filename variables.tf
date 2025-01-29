
variable "tags" {
  description = "A map of tags to assign to the resources"
  type        = map(string)
  default     = null
}

variable "slack_team_name" {
  description = "Name of slack workspace"
  type        = string
}

variable "source_account" {
  description = "The AWS account ID of the account that will be sending the cost alerts"
  type        = string
}

variable "alert_config" {
  type = map(object({
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
}
