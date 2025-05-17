locals {
  public_records    = []
  subdomain_records = []
  main_private_records = [
    {
      name    = "test_record_main"
      type    = "A"
      ttl     = 300
      records = ["10.0.16.200"]
    }
  ]
  dev_private_records = [
    {
      name    = "test_record_dev"
      type    = "A"
      ttl     = 300
      records = ["10.1.16.200"]
    }
  ]
  prod_private_records = []
}

