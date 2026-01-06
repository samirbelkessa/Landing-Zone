# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║ Module: policy-assignments (G03)                                              ║
# ║ Purpose: Azure Policy Assignments for CAF Landing Zone                        ║
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
