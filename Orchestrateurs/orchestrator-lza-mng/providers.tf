################################################################################
# Provider Configuration
# Orchestrator: Management Layer (M01-M08)
################################################################################

provider "azurerm" {
  subscription_id = "b016bf4d-0eda-4613-b434-4d1fb841c3cb"  
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
    log_analytics_workspace {
      permanently_delete_on_destroy = false
    }
  }

  # Optionally specify subscription
  # subscription_id = var.subscription_id
}

# Secondary provider for DR region (if needed)
provider "azurerm" {
  subscription_id = "b016bf4d-0eda-4613-b434-4d1fb841c3cb"
  alias = "secondary"
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }

  # Same subscription, different region resources
  # subscription_id = var.subscription_id
}