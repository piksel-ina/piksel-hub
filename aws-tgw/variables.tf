# --- Common Variables ---
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

variable "account_ids" {
  description = "Account IDs to associate"
  type        = map(string)
}

variable "vpc_id_shared" {
  type = string
}

variable "vpc_cidr_block_shared" {
  description = "CIDR block of the shared VPC"
  type        = string
}

variable "private_subnets" {
  description = "values of private subnets"
  type        = list(string)
}