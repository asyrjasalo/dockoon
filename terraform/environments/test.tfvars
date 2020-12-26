# Scope

location = "WestEurope"
prefix   = "aswe"

# Tags

app           = "dockoon"
environment   = "test"
contact_email = "dockoon@raas.dev"

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

# DNS

dns_zone_name    = "raas.dev"
dns_zone_rg_name = "aswe-dev-vdc-rg"
