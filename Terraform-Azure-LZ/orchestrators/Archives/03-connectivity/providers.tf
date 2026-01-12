# =============================================================================
# PROVIDERS CONFIGURATION
# =============================================================================
# Le module AVM nécessite les providers suivants :
# - azurerm : Provider Azure standard
# - azapi   : Provider Azure API (pour les fonctionnalités avancées)
# - modtm   : Provider pour la télémétrie du module (optionnel)
# - random  : Provider pour génération de valeurs aléatoires
# =============================================================================

terraform {
  required_version = "~> 1.12"

  required_providers {
    # Provider Azure Resource Manager
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }

    # Provider Azure API - Utilisé par AVM pour des opérations avancées
    azapi = {
      source  = "azure/azapi"
      version = "~> 2.4"
    }

    # Provider Random - Pour génération de noms uniques si nécessaire
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }

  # ==========================================================================
  # BACKEND CONFIGURATION - Brainboard
  # ==========================================================================
  # Note: Brainboard gère automatiquement le backend
  # Si tu utilises un autre backend, décommente et configure :
  #
  # backend "azurerm" {
  #   resource_group_name  = "rg-terraform-state"
  #   storage_account_name = "stterraformstate"
  #   container_name       = "tfstate"
  #   key                  = "connectivity/australia.tfstate"
  # }
}

# =============================================================================
# PROVIDER AZURERM - Connectivity Subscription
# =============================================================================
provider "azurerm" {
  features {
    # Empêcher la suppression accidentelle des Resource Groups non vides
    resource_group {
      prevent_deletion_if_contains_resources = true
    }

    # Configuration Key Vault
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }

    # Configuration Virtual Machine (si nécessaire)
    virtual_machine {
      delete_os_disk_on_deletion     = true
      skip_shutdown_and_force_delete = false
    }
  }

  subscription_id = var.connectivity_subscription_id
  tenant_id       = var.tenant_id

  # Optionnel : Si tu utilises un Service Principal
  # client_id       = var.client_id
  # client_secret   = var.client_secret
}

# =============================================================================
# PROVIDER AZAPI
# =============================================================================
# Ce provider est utilisé par le module AVM pour des opérations avancées
# Il hérite automatiquement de la configuration azurerm
provider "azapi" {
  # Hérite de la subscription du provider azurerm
}
