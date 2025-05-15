# --- Common Variables ---
variable "project" {
  description = "The name of the project"
  type        = string
  default     = "Piksel"
}

variable "environment" {
  description = "The environment of the deployment"
  type        = string
}

variable "aws_region" {
  description = "Region to deploy resources in"
  type        = string
  default     = "ap-southeast-3"
}

variable "default_tags" {
  description = "A map of default tags to apply to all AWS resources"
  type        = map(string)
  default     = {}
}

# --- AWS OIDC Variables ---
variable "aws_token" {
  type      = string
  ephemeral = true
}

variable "aws_role" {
  type = string
}

# --- VPC Configuration Variables ---
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "az_count" {
  description = "Number of Availability Zones to use for subnets"
  type        = number
  default     = 2
}

# --- NAT Gateway Configuration ---
variable "single_nat_gateway" {
  description = "Enable a single NAT Gateway for all private subnets (cheaper, less availability)"
  type        = bool
  default     = true
}

variable "one_nat_gateway_per_az" {
  description = "Enable one NAT Gateway per Availability Zone (higher availability, higher cost)"
  type        = bool
  default     = false
}

# --- VPC Flow Logs Configuration ---
variable "enable_flow_log" {
  description = "Enable VPC Flow Logs for monitoring network traffic"
  type        = bool
  default     = false
}

variable "flow_log_retention_days" {
  description = "Retention period for VPC Flow Logs in CloudWatch (in days)"
  type        = number
  default     = 90
}

# --- Records Variables ---
variable "enable_records_public" {
  description = "Enable public DNS records for the main public zone"
  type        = bool
  default     = false
}

variable "enable_records_subdomain" {
  description = "Enable public DNS records for the app subdomain"
  type        = bool
  default     = false
}

variable "enable_records_private_dev" {
  description = "Enable private DNS records for the dev environment"
  type        = bool
  default     = false
}

variable "enable_records_private_prod" {
  description = "Enable private DNS records for the dev environment"
  type        = bool
  default     = false
}

# --- Other Environment Variables ---
variable "spoke_vpc_cidrs_dev" {
  description = "values of spoke VPC CIDR blocks"
  type        = string
  default     = ""
}

variable "vpc_id_dev" {
  description = "values of VPC ID for dev environment"
  type        = string
}