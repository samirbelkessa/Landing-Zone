# =============================================================================
# PROVIDERS.TF - PROVIDER CONFIGURATION
# =============================================================================
# Orchestrator: 04-connectivity
# 
# NOTE: The connectivity_subscription_id comes from terraform.tfvars
#       Replace __CONNECTIVITY_SUBSCRIPTION_ID__ placeholder before deployment
# =============================================================================

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = false
    }
    virtual_machine {
      delete_os_disk_on_deletion     = true
      skip_shutdown_and_force_delete = false
    }
  }

  subscription_id = var.connectivity_subscription_id

}

# =============================================================================
# PROVIDER AZAPI - For advanced Azure operations
# =============================================================================
provider "azapi" {
  # Inherits subscription from azurerm provider
}

# =============================================================================
# PROVIDER RANDOM - For unique name generation
# =============================================================================
provider "random" {}
