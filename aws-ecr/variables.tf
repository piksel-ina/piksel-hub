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

variable "github_org" {
  description = "The Name of Github Organization to give permission on ECR access"
  type        = string
}

variable "github_repos" {
  description = "List of GitHub repo names that can assume the ECR push role"
  type        = list(string)
}

variable "ecr_repos" {
  type = map(object({
    tag_prefixes               = list(string)
    keep_last                  = optional(number, 2)
    expire_untagged_after_days = optional(number, 7)
  }))
}

