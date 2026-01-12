# =============================================================================
# BACKEND CONFIGURATION - CONNECTIVITY LAYER
# =============================================================================
# Options :
# - Brainboard : Laisse ce fichier vide (géré automatiquement)
# - Azure Storage : Décommente la section ci-dessous
# =============================================================================

# terraform {
#   backend "azurerm" {
#     resource_group_name  = "rg-terraform-state"
#     storage_account_name = "stterraformstateaue"
#     container_name       = "tfstate"
#     key                  = "connectivity/australia.tfstate"
#   }
# }

# =============================================================================
# REMOTE STATE - Récupérer les outputs des autres couches
# =============================================================================

# Décommenter quand la couche Management est déployée
# data "terraform_remote_state" "management" {
#   backend = "azurerm"
#   config = {
#     resource_group_name  = "rg-terraform-state"
#     storage_account_name = "stterraformstateaue"
#     container_name       = "tfstate"
#     key                  = "management/australia.tfstate"
#   }
# }
