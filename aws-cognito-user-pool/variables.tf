variable "aws_region" {
  description = "Region to deploy resources in"
  type        = string
  default     = "ap-southeast-3"
}

variable "default_tags" {
  description = "Default tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "user_pool_name" {
  description = "Name of the Cognito User Pool"
  type        = string
}

variable "clients" {
  description = "List of clients to create"
  type = list(object({
    name                 = string
    allowed_oauth_flows  = list(string)
    allowed_oauth_scopes = list(string)
    callback_urls        = list(string)
    logout_urls          = list(string)
    generate_secret      = optional(bool, false)
  }))
  default = []
}

variable "domain" {
  description = "Custom domain for the user pool (optional)"
  type        = string
  default     = ""
}

variable "certificate_arn" {
  description = "ARN of the ACM certificate for the custom domain (required if domain is set)"
  type        = string
  default     = ""
}
