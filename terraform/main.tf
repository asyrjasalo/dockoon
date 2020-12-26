locals {
  rg_name  = "${var.prefix}-${var.environment}-${var.app}-rg"
  aci_name = "${var.prefix}-${var.environment}-${var.app}-aci"
  sa_name  = "${var.prefix}${var.environment}${var.app}sa"

  tags = {
    "app"         = var.app
    "contact"     = var.contact_email
    "environment" = var.environment
  }
}
