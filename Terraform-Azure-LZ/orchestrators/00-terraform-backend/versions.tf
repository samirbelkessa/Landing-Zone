# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║ Module: F00-terraform-backend                                                 ║
# ║ Purpose: Storage Account for centralized Terraform state files               ║
# ║ Location: Management Subscription (Platform)                                  ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.80.0"
    }
  }
}

# ─────────────────────────────────────────────────────────────────────────────────
# Provider - Management Subscription
# ─────────────────────────────────────────────────────────────────────────────────

provider "azurerm" {
  subscription_id = var.management_subscription_id

  features {
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
  }
}
