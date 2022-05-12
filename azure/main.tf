terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.97.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "pcloud_rg" {
  name     = var.rg_name
  location = var.rg_location
}

resource "azurerm_key_vault" "keyvault" {
  name                        = var.kv_name
  location                    = azurerm_resource_group.pcloud_rg.location
  resource_group_name         = azurerm_resource_group.pcloud_rg.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Backup", "Create", "Decrypt", "Delete", "Encrypt", "Get", "Import", "List", "Purge", "Recover", "Sign", "UnwrapKey", "Update", "Verify", "WrapKey"
    ]

    secret_permissions = [
      "Backup", "Delete", "Get", "List", "Purge", "Recover", "Restore", "Set"
    ]

    storage_permissions = [
      "Get",
    ]
  }
}

resource "azurerm_kubernetes_cluster" "kubecluster" {
  name                = var.k8s_cluster_name
  location            = azurerm_resource_group.pcloud_rg.location
  resource_group_name = azurerm_resource_group.pcloud_rg.name
  dns_prefix          = "${var.k8s_cluster_name}-aks"

  default_node_pool {
    name           = "default"
    node_count     = var.k8s_node_count
    vm_size        = var.k8s_vm_size
    vnet_subnet_id = azurerm_subnet.aks_subnet.id
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin     = "kubenet"
    load_balancer_sku  = "Standard"
    service_cidr       = "10.0.0.0/16"
    dns_service_ip     = "10.0.0.10"
    docker_bridge_cidr = "172.17.0.1/16"
  }

  key_vault_secrets_provider {
    secret_rotation_enabled = false
  }
}

resource "azurerm_user_assigned_identity" "aks_user_identity" {
  name                = "aks-dns-identity"
  resource_group_name = azurerm_resource_group.pcloud_rg.name
  location            = azurerm_resource_group.pcloud_rg.location
}

resource "azurerm_role_assignment" "aks_private_dns_role" {
  scope                = azurerm_private_dns_zone.db_dns_zone.id
  role_definition_name = "Private DNS Zone Contributor"
  principal_id         = azurerm_user_assigned_identity.aks_user_identity.principal_id
}

#----- Networking -------------

resource "azurerm_virtual_network" "vnet" {
  name                = "ohia-vn"
  location            = azurerm_resource_group.pcloud_rg.location
  resource_group_name = azurerm_resource_group.pcloud_rg.name
  address_space       = ["192.168.0.0/16"]
}

resource "azurerm_subnet" "aks_subnet" {
  name                 = "ohia-aks-subnet"
  resource_group_name  = azurerm_resource_group.pcloud_rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["192.168.1.0/24"]
  service_endpoints    = ["Microsoft.Sql", "Microsoft.KeyVault", "Microsoft.ContainerRegistry"]
}

resource "azurerm_subnet" "db_subnet" {
  name                 = "ohia-subnet-mysql"
  resource_group_name  = azurerm_resource_group.pcloud_rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["192.168.2.0/24"]
  service_endpoints    = ["Microsoft.Storage"]

  delegation {
    name = "fs"
    service_delegation {
      name = "Microsoft.DBforMySQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}


resource "azurerm_private_dns_zone" "db_dns_zone" {
  name                = "ohia.mysql.database.azure.com"
  resource_group_name = azurerm_resource_group.pcloud_rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "example" {
  name                  = "az-kubenet-link"
  private_dns_zone_name = azurerm_private_dns_zone.db_dns_zone.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  resource_group_name   = azurerm_resource_group.pcloud_rg.name
}

#----- DB -------------

resource "azurerm_mysql_flexible_server" "mysql" {
  name                   = "ohiamttsql"
  resource_group_name    = azurerm_resource_group.pcloud_rg.name
  location               = azurerm_resource_group.pcloud_rg.location
  administrator_login    = "psqladmin"
  administrator_password = "$o!z^hqXUU6cW2XG2Le"
  backup_retention_days  = 7
  delegated_subnet_id    = azurerm_subnet.db_subnet.id
  private_dns_zone_id    = azurerm_private_dns_zone.db_dns_zone.id
  sku_name               = "B_Standard_B1ms"
  zone                   = "1"

  depends_on = [azurerm_private_dns_zone_virtual_network_link.example]
}

resource "azurerm_mysql_flexible_database" "monica" {
  name                = "monica"
  resource_group_name = azurerm_resource_group.pcloud_rg.name
  server_name         = azurerm_mysql_flexible_server.mysql.name
  charset             = "utf8"
  collation           = "utf8_unicode_ci"
}

#------------------------
