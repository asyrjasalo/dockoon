# Scope

location = "WestEurope"
prefix   = "slug"

# Tags

app           = "dockoon"
environment   = "test"
contact_email = "yourmail@yourdomain.dev"

# ACI

container_name = "mockoon"
docker_image   = "asyrjasalo/mockoon:alpine"
environment_variables = {
  NODE_ENV = "production"
}
commands = ["sh", "runner.sh", "start", "--data", "/apis/apis.json", "-i", "0"]
volumes = {
  "apis" = "/apis"
}

# VNET - use your VPN Gateway to access

vnet_address_space = "172.16.128.0/24"
