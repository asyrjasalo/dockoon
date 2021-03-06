# Scope

location = "WestEurope"
prefix   = "slug"

# Tags

app           = "dockoon"
environment   = "prod"
contact_email = "yourmail@yourdomain.dev"

# ACI

# visibility = "Private"  # default - use gateway to access
container_name = "mockoon"
docker_image   = "asyrjasalo/mockoon:alpine"
environment_variables = {
  NODE_ENV = "production"
}
commands = ["sh", "runner.sh", "start", "--data", "/apis/apis.json", "-i", "0"]
volumes = {
  "apis" = "/apis"
}

# LAW

law_sku = "PerGB2018"

# DNS

dns_zone_name    = "yourdomain.dev"
dns_zone_rg_name = "slug-prod-dns-rg"

# VNET

vnet_address_space = "10.0.2.0/24"

# AppGw

enable_appgw  = true
cert_pfx_path = "secrets/cert.pfx"
cert_password = "P4ssw0rd_of_pfx!"
