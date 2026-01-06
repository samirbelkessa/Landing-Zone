# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║ Module: policy-exemptions (G04)                                               ║
# ║ Purpose: Azure Policy Exemptions for CAF Landing Zone                         ║
# ║ Description: Manages policy exemptions for brownfield migration and           ║
# ║              legitimate exceptions to governance policies                     ║
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
