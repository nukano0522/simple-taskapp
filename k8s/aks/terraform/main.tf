# https://learn.microsoft.com/en-us/azure/aks/learn/quick-kubernetes-deploy-terraform?pivots=development-environment-azure-cli

resource "azurerm_resource_group" "rg" {
  location = var.location
  name     = var.resource_group_name
}

resource "random_pet" "azurerm_kubernetes_cluster_dns_prefix" {
  prefix = "nk1"
}

# 仮想ネットワーク
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${var.aks_name}"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}


# Application Gateway 用サブネット
resource "azurerm_subnet" "appgw_subnet" {
  name                 = "subnet-appgw"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.appgw_subnet_cidr]
}


# AKS 用サブネット
resource "azurerm_subnet" "aks_subnet" {
  name                 = "subnet-aks"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.aks_subnet_cidr]
}

# Application Gateway 用のパブリック IP
resource "azurerm_public_ip" "appgw_pip" {
  name                = "pip-${var.aks_name}-appgw"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Application Gateway の作成
resource "azurerm_application_gateway" "appgw" {
  name                = "appgw-${var.aks_name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "gateway-ip-configuration"
    subnet_id = azurerm_subnet.appgw_subnet.id
  }

  frontend_port {
    name = "http-port"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "frontend-ip-configuration"
    public_ip_address_id = azurerm_public_ip.appgw_pip.id
  }

  backend_address_pool {
    name = "default-backend-pool"
  }

  http_listener {
    name                           = "http-listener"
    frontend_ip_configuration_name = "frontend-ip-configuration"
    frontend_port_name             = "http-port"
    protocol                       = "Http"
  }

  backend_http_settings {
    name                  = "default-backend-settings"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 20
  }

  request_routing_rule {
    name                       = "rule1"
    priority                   = 1
    rule_type                  = "Basic"
    http_listener_name         = "http-listener"
    backend_address_pool_name  = "default-backend-pool"
    backend_http_settings_name = "default-backend-settings"
  }

  tags = {
    environment = "production"
  }
}

# AKS クラスタの作成
resource "azurerm_kubernetes_cluster" "k8s" {
  location            = var.location
  name                = var.aks_name
  resource_group_name = var.resource_group_name
  dns_prefix          = var.dns_prefix

  identity {
    type = "SystemAssigned"
  }

  default_node_pool {
    name       = "agentpool"
    vm_size    = "Standard_D2_v2"
    node_count = var.node_count
    vnet_subnet_id = azurerm_subnet.aks_subnet.id
  }
  linux_profile {
    admin_username = var.username

    ssh_key {
      key_data = azapi_resource_action.ssh_public_key_gen.output.publicKey
    }
  }
  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
    network_policy      = "azure"
    service_cidr      = var.service_cidr  # サービス CIDR を追加
    dns_service_ip    = var.dns_service_ip     # サービス DNS IP を指定
  }
  ingress_application_gateway {
    gateway_id = azurerm_application_gateway.appgw.id
  }

  depends_on = [
    azurerm_virtual_network.vnet,
    azurerm_subnet.appgw_subnet,
    azurerm_subnet.aks_subnet,
    azurerm_public_ip.appgw_pip,
    azurerm_application_gateway.appgw,
  ]
}

# ロール割り当て
# https://blog.nnstt1.dev/posts/2022/11/02/deploy-aks-agw-with-terraform/
resource "azurerm_role_assignment" "aks_agw_subnet_contributor" {
  scope                = azurerm_subnet.appgw_subnet.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_kubernetes_cluster.k8s.ingress_application_gateway[0].ingress_application_gateway_identity[0].object_id
  
  depends_on = [azurerm_kubernetes_cluster.k8s]
}

resource "azurerm_role_assignment" "agic_rg_role" {
  scope                = azurerm_resource_group.rg.id
  role_definition_name = "Reader"
  principal_id         = azurerm_kubernetes_cluster.k8s.ingress_application_gateway[0].ingress_application_gateway_identity[0].object_id

  depends_on = [azurerm_kubernetes_cluster.k8s]
}

resource "azurerm_role_assignment" "agic_agw_role" {
  scope                = azurerm_application_gateway.appgw.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_kubernetes_cluster.k8s.ingress_application_gateway[0].ingress_application_gateway_identity[0].object_id

  depends_on = [azurerm_application_gateway.appgw, azurerm_kubernetes_cluster.k8s]
}