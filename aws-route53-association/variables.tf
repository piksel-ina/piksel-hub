variable "spoke_vpc_ids" {
  description = "List of spoke VPC IDs"
  type        = list(string)
  default     = [""]
}

variable "authorization_zone" {
  description = "Zone on which VPCs will be authorized"
  type        = string
  default     = ""
}

variable "account_ids" {
  description = "Account IDs to associate"
  type        = map(string)
}

variable "default_tags" {
  description = "Default tags to apply to all resources"
  type        = map(string)
  default     = {}
}
