# --- Authorization for VPC Association ---
resource "aws_route53_vpc_association_authorization" "this" {
  for_each   = toset(var.spoke_vpc_ids)
  vpc_id     = each.value
  zone_id    = var.authorization_zone
}

variable "spoke_vpc_ids" {
  description = "List of spoke VPC IDs"
  type        = list(string)
  default = [""]
}

variable "authorization_zone"{
  description = "Zone on which VPCs will be authorized"
  type = string
  default = ""
}

output "authorization_ids" {
  description = "The calculated unique identifiers for the association"
  value = {for k,v in aws_route53_vpc_association_authorization.this : k => v.id}  
}