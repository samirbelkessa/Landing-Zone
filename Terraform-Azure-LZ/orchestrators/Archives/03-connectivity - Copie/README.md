# 🌏 Azure Landing Zone - Connectivity Layer (Australia)

## 📋 Vue d'ensemble

Ce projet déploie la couche **Connectivity** de l'Azure Landing Zone pour l'Australie en utilisant le module [Azure Verified Module (AVM) Hub and Spoke](https://registry.terraform.io/modules/Azure/avm-ptn-alz-connectivity-hub-and-spoke-vnet/azurerm/latest).

### Architecture déployée

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         CONNECTIVITY SUBSCRIPTION                            │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────────────────┐     ┌─────────────────────────────┐       │
│  │   HUB AUSTRALIA EAST        │     │  HUB AUSTRALIA SOUTHEAST    │       │
│  │   (PRIMARY)                 │◄───►│  (DR)                       │       │
│  │   10.0.0.0/22               │mesh │  10.1.0.0/22                │       │
│  ├─────────────────────────────┤peer ├─────────────────────────────┤       │
│  │ • Azure Firewall Premium    │     │ • Azure Firewall Premium    │       │
│  │ • Azure Bastion Standard    │     │ • Azure Bastion Standard    │       │
│  │ • VPN Gateway VpnGw2AZ      │     │ • (No Gateway - DR)         │       │
│  │ • Private DNS Zones         │     │ • DNS Resolver only         │       │
│  │ • Private DNS Resolver      │     │                             │       │
│  │ • Route Tables (UDR)        │     │ • Route Tables (UDR)        │       │
│  └─────────────────────────────┘     └─────────────────────────────┘       │
│                                                                             │
│  ❌ DDoS Protection Plan = DISABLED (Cloudflare)                            │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## 📁 Structure des fichiers

```
environments/australia/
├── providers.tf      # Configuration Terraform & providers
├── variables.tf      # Définition des variables
├── locals.tf         # Valeurs locales calculées
├── main.tf           # Configuration du module AVM
├── outputs.tf        # Outputs pour les autres modules
└── terraform.tfvars  # Valeurs du projet (⚠️ ne pas commiter les secrets)
```

## 🚀 Guide de déploiement

### Prérequis

1. **Terraform** >= 1.12
2. **Azure CLI** authentifié
3. **Permissions** : Owner ou Contributor sur la Connectivity Subscription
4. **Brainboard** configuré (ou backend Terraform)

### Étape 1 : Configuration des credentials

```bash
# Option A : Azure CLI
az login
az account set --subscription "CONNECTIVITY_SUBSCRIPTION_ID"

# Option B : Service Principal (pour CI/CD)
export ARM_CLIENT_ID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
export ARM_CLIENT_SECRET="xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
export ARM_SUBSCRIPTION_ID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
export ARM_TENANT_ID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
```

### Étape 2 : Personnaliser les variables

1. Ouvrir `terraform.tfvars`
2. Remplacer les valeurs `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` par tes vraies valeurs
3. Adapter les connexions VPN si nécessaire
4. Adapter les zones DNS forwarding si nécessaire

### Étape 3 : Initialisation

```bash
cd environments/australia
terraform init
```

### Étape 4 : Validation

```bash
# Valider la syntaxe
terraform validate

# Formater le code
terraform fmt -recursive

# Voir le plan d'exécution
terraform plan -out=tfplan
```

### Étape 5 : Déploiement

```bash
# Appliquer le plan
terraform apply tfplan

# Ou directement (avec confirmation)
terraform apply
```

### Étape 6 : Vérification

```bash
# Afficher les outputs
terraform output

# Vérifier les ressources créées
terraform state list
```

## 📊 IP Plan - Récapitulatif

### Australia East (10.0.0.0/22)

| Subnet | CIDR | Usage |
|--------|------|-------|
| GatewaySubnet | 10.0.0.0/26 | VPN/ExpressRoute Gateway |
| AzureFirewallSubnet | 10.0.0.64/26 | Azure Firewall Premium |
| AzureFirewallManagementSubnet | 10.0.0.128/26 | Firewall Management |
| AzureBastionSubnet | 10.0.0.192/26 | Azure Bastion |
| snet-hub-dns | 10.0.1.0/27 | DNS Resolver Inbound |
| snet-hub-dns-out | 10.0.1.32/27 | DNS Resolver Outbound |
| snet-hub-mgmt | 10.0.1.64/26 | Management VMs |
| snet-hub-shared | 10.0.2.0/24 | Services Partagés |
| snet-hub-pe | 10.0.3.0/24 | Private Endpoints |

### Australia Southeast (10.1.0.0/22)

| Subnet | CIDR | Usage |
|--------|------|-------|
| GatewaySubnet | 10.1.0.0/26 | VPN/ExpressRoute Gateway |
| AzureFirewallSubnet | 10.1.0.64/26 | Azure Firewall Premium |
| AzureFirewallManagementSubnet | 10.1.0.128/26 | Firewall Management |
| AzureBastionSubnet | 10.1.0.192/26 | Azure Bastion |
| snet-hub-dns | 10.1.1.0/27 | DNS Resolver Inbound |
| snet-hub-dns-out | 10.1.1.32/27 | DNS Resolver Outbound |
| snet-hub-mgmt | 10.1.1.64/26 | Management VMs |
| snet-hub-shared | 10.1.2.0/24 | Services Partagés |
| snet-hub-pe | 10.1.3.0/24 | Private Endpoints |

## ⚙️ Configuration des ressources

### Azure Firewall

- **Tier** : Premium (IDPS, TLS inspection)
- **Zones** : 1, 2, 3 (zone-redundant)
- **Threat Intelligence** : Alert mode
- **Forced Tunneling** : Activé (Management subnet)

### Azure Bastion

- **SKU** : Standard
- **Features** : Tunneling, File Copy, IP Connect
- **Scale Units** : 2

### VPN Gateway

- **SKU** : VpnGw2AZ (zone-redundant)
- **Mode** : Active-Active
- **BGP** : Configurable

### Private DNS Zones

Toutes les zones Private Link sont créées automatiquement :
- privatelink.blob.core.windows.net
- privatelink.file.core.windows.net
- privatelink.database.windows.net
- ... (liste complète dans le module)

## 🔧 Personnalisation

### Ajouter une connexion VPN

```hcl
# Dans terraform.tfvars
vpn_connections = {
  onprem-dc1 = {
    name            = "Datacenter-Sydney"
    gateway_address = "203.0.113.1"
    address_space   = ["192.168.0.0/16"]
    shared_key      = "YourSecretKey"
    bgp_enabled     = true
    bgp_asn         = 65001
    bgp_peering_address = "192.168.1.1"
    ipsec_policy = {
      dh_group         = "DHGroup14"
      ike_encryption   = "AES256"
      ike_integrity    = "SHA256"
      ipsec_encryption = "AES256"
      ipsec_integrity  = "SHA256"
      pfs_group        = "PFS14"
    }
  }
}
```

### Ajouter du DNS forwarding

```hcl
# Dans terraform.tfvars
dns_forward_zones = {
  corp = {
    domain_name = "corp.contoso.com."
    destination_ip_addresses = {
      dc1 = "192.168.1.10"
      dc2 = "192.168.1.11"
    }
  }
}
```

### Activer ExpressRoute

```hcl
# Dans terraform.tfvars
enable_expressroute_gateway = true
expressroute_gateway_sku    = "ErGw2AZ"
```

## 📤 Outputs importants

| Output | Description | Usage |
|--------|-------------|-------|
| `hub_vnet_ids` | IDs des Hub VNets | Peering des Spokes |
| `firewall_private_ips` | IPs privées des Firewalls | UDR dans les Spokes |
| `dns_resolver_inbound_ips` | IPs DNS Resolver | Configuration DNS des VNets |
| `route_table_ids_user_subnets` | IDs Route Tables | Association aux Spokes |
| `spoke_peering_config` | Config complète pour Spokes | Module Spoke VNet |

## ⚠️ Points d'attention

1. **DDoS Protection** : Désactivé car Cloudflare est utilisé
2. **Firewall Policy Rules** : Les Rule Collection Groups doivent être ajoutés via un module custom (C03)
3. **Secrets** : Ne pas commiter les shared keys VPN - utiliser Key Vault
4. **Coûts** : Azure Firewall Premium et VPN Gateway ont des coûts significatifs

## 🔗 Prochaines étapes

1. Déployer le module **Firewall Policy (C03)** pour les règles Fortinet
2. Déployer les **Spoke VNets (L02)** avec peering vers les Hubs
3. Configurer les **NSG et Flow Logs (S05)**
4. Déployer **Application Gateway WAF (C13)** si nécessaire

## 📚 Références

- [Module AVM Hub & Spoke](https://registry.terraform.io/modules/Azure/avm-ptn-alz-connectivity-hub-and-spoke-vnet/azurerm/latest)
- [Azure CAF Landing Zones](https://aka.ms/alz)
- [Azure Firewall Documentation](https://docs.microsoft.com/azure/firewall/)
- [Azure Bastion Documentation](https://docs.microsoft.com/azure/bastion/)
