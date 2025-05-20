output "security_groups" {
  description = "Combined Security Groups Outputs"
  value = merge(
    {
      "hub-to-spoke-sg" = {
        id          = module.hub_sg.security_group_id
        arn         = module.hub_sg.security_group_arn
        name        = module.hub_sg.security_group_name
        description = module.hub_sg.security_group_description
      }
    },
    {
      "ecr-endpoint-sg" = {
        id          = module.ecr_endpoint_sg.security_group_id
        arn         = module.ecr_endpoint_sg.security_group_arn
        name        = module.ecr_endpoint_sg.security_group_name
        description = module.ecr_endpoint_sg.security_group_description
      }
    }
  )
}