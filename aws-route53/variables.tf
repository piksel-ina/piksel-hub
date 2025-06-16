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

# --- Hostname Variables ---
variable "domain_name" {
  type    = string
  default = "pik-sel.id"
}

variable "subdomain_name_dev" {
  type    = string
  default = "dev.pik-sel.id"
}

variable "private_domain_name_hub" {
  type    = string
  default = "piksel.internal"
}

# variable "private_domain_name_dev" {
#   type    = string
#   default = "dev.piksel.internal"
# }

# variable "private_domain_name_prod" {
#   type    = string
#   default = "prod.piksel.internal"
# }

variable "vpc_id_shared" {
  type = string
}

# --- Records Variables ---
variable "public_records" {
  description = "Public DNS records for the main public zone"
  type = list(object({
    name    = string
    type    = string
    ttl     = number
    records = list(string)
  }))
  default = []
}

variable "subdomain_records_dev" {
  description = "Public DNS records for the main public zone"
  type = list(object({
    name    = string
    type    = string
    ttl     = number
    records = list(string)
  }))
  default = []
}

variable "main_private_records" {
  description = "Public DNS records for the main public zone"
  type = list(object({
    name    = string
    type    = string
    ttl     = number
    records = list(string)
  }))
  default = []
}

# variable "dev_private_records" {
#   description = "Public DNS records for the main public zone"
#   type = list(object({
#     name    = string
#     type    = string
#     ttl     = number
#     records = list(string)
#   }))
#   default = []
# }

# variable "prod_private_records" {
#   description = "Public DNS records for the main public zone"
#   type = list(object({
#     name    = string
#     type    = string
#     ttl     = number
#     records = list(string)
#   }))
#   default = []
# }

# --- Inbound and Outbound Rules Variables ---
variable "create_inbound_resolver_endpoint" {
  description = "Create an inbound resolver endpoint"
  type        = bool
  default     = true
}

variable "create_outbound_resolver_endpoint" {
  description = "Create an outbound resolver endpoint"
  type        = bool
  default     = false
}

variable "vpc_cidr_block_shared" {
  description = "CIDR block of the shared VPC"
  type        = string
}

variable "private_subnets" {
  description = "values of private subnets"
  type        = list(string)
}


variable "spoke_vpc_cidrs" {
  description = "List of spoke VPC CIDRs"
  type        = list(string)
  default     = [""]
}

variable "cross_account_configs" {
  description = "List of trusted accounts and their OIDC details for ExternalDNS cross-account access"
  type = list(object({
    env                  = string
    account_id           = string
    oidc_provider_url    = string
    namespace            = string
    service_account_name = string
    hosted_zone_names    = list(string)
  }))
}
