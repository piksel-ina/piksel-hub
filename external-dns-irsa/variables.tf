variable "default_tags" {
  description = "Default tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "project" {
  description = "The name of the project"
  type        = string
}

variable "environment" {
  description = "The name of the environment"
  type        = string
}

variable "zone_ids" {
    description = "Maps of Zone Ids"
}

variable "cross_account_configs" {
  description = "List of trusted accounts and their OIDC details for ExternalDNS cross-account access"
  type = list(object({
    env                  = string
    account_id           = string
    namespace            = string
    service_account_name = string
    hosted_zone_names    = list(string)
  }))
}
