variable "project" {
  description = "The name of the project"
  type        = string
}

variable "current_account_id" {
  description = "The ID of current account"
  type        = string
}

variable "account_ids" {
  description = "Map of environment names to AWS account IDs for cross-account ECR access"
  type        = map(string)
}

variable "default_tags" {
  description = "Default tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "github-org" {
  description = "The Name of Github Organization to give permission on ECR access"
  type        = string
  default     = "piksel-ina"
}

variable "github-repo" {
  description = "The Repository name to grant ECR Access permissions"
  type        = string
  default     = "piksel-core"
}

