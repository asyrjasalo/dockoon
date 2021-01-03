# Scope

location = "WestEurope"
prefix   = "slug"

# Tags

app           = "dockoon"
environment   = "test"
contact_email = "yourmail@yourdomain.dev"

# ACI

visibility = "Public"
container_name = "mockoon"
docker_image   = "asyrjasalo/mockoon:alpine"
environment_variables = {
  NODE_ENV = "production"
}
commands = ["sh", "runner.sh", "start", "--data", "/apis/apis.json", "-i", "0"]
volumes = {
  "apis" = "/apis"
}
