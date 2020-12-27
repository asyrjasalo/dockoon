locals {
  tags = {
    "app"         = var.app
    "contact"     = var.contact_email
    "environment" = var.environment
  }
}

# Scope

variable "location" {
  type    = string
  default = "WestEurope"
}

variable "prefix" {
  type = string
}

# Tags

variable "app" {
  type    = string
  default = "dockoon"
}

variable "environment" {
  type = string
}

variable "contact_email" {
  type = string
}

# ACI

variable "restart_policy" {
  type    = string
  default = "Always"
}

variable "container_name" {
  type    = string
  default = "mockoon"
}

variable "docker_image" {
  type    = string
  default = "asyrjasalo/mockoon:alpine"
}

variable "commands" {
  type    = list(string)
  default = null
}

variable "environment_variables" {
  type    = map(any)
  default = {}
}

variable "secure_environment_variables" {
  type    = map(any)
  default = {}
}

variable "vcpu_count" {
  type    = number
  default = 2
}

variable "memory_gbs" {
  type    = number
  default = 1.5
}

variable "ports" {
  type = list(number)
  default = [8080]
}

variable "volumes" {
  type = map(any)
  default = {}
}

# DNS

variable "dns_zone_name" {
  type    = string
  default = ""
}

variable "dns_zone_rg_name" {
  type    = string
  default = ""
}
