locals {
  public_records    = []
  subdomain_records = []
  main_private_records = [
    {
      name    = "test"
      type    = "A"
      ttl     = 300
      records = ["10.0.15.200"]
    }
  ]
  dev_private_records = [
    {
      name    = "test"
      type    = "A"
      ttl     = 300
      records = ["10.1.15.200"]
    }
  ]
  prod_private_records = []
}

