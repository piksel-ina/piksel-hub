# --- Variables ---
variable "default_tags" {
  description = "Default tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "vpc_id_shared" {
  description = "The ID of the VPC to associate with the resolver rule"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the hub VPC"
  type        = string
}

variable "spoke_vpc_cidrs" {
  description = "List of CIDR blocks for spoke VPCs"
  type        = list(string)
}
