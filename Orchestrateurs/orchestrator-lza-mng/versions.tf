################################################################################
# Terraform and Provider Requirements
# Orchestrator: Management Layer (M01-M08)
################################################################################

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.80.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.0"
    }
  }

  # Backend configuration for Brainboard
  # Uncomment and configure for your environment
  # backend "azurerm" {
  #   resource_group_name  = "rg-terraform-state"
  #   storage_account_name = "stterraformstate"
  #   container_name       = "tfstate"
  #   key                  = "management/terraform.tfstate"
  # }
}