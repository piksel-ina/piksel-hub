variable "user_pool_name" {
  description = "Name of the Cognito User Pool"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "clients" {
  description = "List of clients to create"
  type = list(object({
    name                 = string
    allowed_oauth_flows  = list(string)
    allowed_oauth_scopes = list(string)
    callback_urls        = list(string)
    logout_urls          = list(string)
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
