################################################################################
# providers.tf - Management Layer Orchestrator
################################################################################

provider "azurerm" {
  subscription_id = "b016bf4d-0eda-4613-b434-4d1fb841c3cb"
  features {

    resource_group {
      prevent_deletion_if_contains_resources = true
    }
    key_vault {
      purge_soft_delete_on_destroy = false
    }
    log_analytics_workspace {
      permanently_delete_on_destroy = false
    }
  }
}
