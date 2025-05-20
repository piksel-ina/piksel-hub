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
  default     = "piksel"
}

variable "github-repo" {
  description = "The Repository name to grant ECR Access permissions"
  type        = string
  default     = "piksel-core"
}

# --- Endpoints Variables ---

variable "ecr_endpoint_sg_id" {
  description = "ECR endpoint security groups"
}

variable "vpc_id_shared" {
  description = "The ID of the VPC to associate with the security group"
  type        = string
}

variable "region" {
  description = "Region to deploy resources in"
  type        = string
  default     = "ap-southeast-3"
}

variable "private_subnet_ids" {
  description = "Private Subnets ID"
  type        = list(string)
}

variable "private_route_table_ids" {
  description = "List of route table IDs"
  type        = list(string)
}