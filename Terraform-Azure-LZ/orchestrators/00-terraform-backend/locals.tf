# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║ Locals - F00 Terraform Backend                                               ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

locals {
  default_tags = {
    ManagedBy = "Terraform"
    Module    = "F00-terraform-backend"
    Purpose   = "Terraform State Storage"
  }

  tags = merge(local.default_tags, var.tags)
}
