variable "resource_group_name" {
  description = "名前のリソースグループ"
  type        = string
  default     = "rg-nukano0522-01"
}

variable "location" {
  description = "Azure のリージョン"
  type        = string
  default     = "Japan East" # 必要に応じて変更
}

variable "aks_name" {
  description = "AKS クラスタの名前"
  type        = string
  default     = "nk-aks"
}

variable "dns_prefix" {
  description = "AKS クラスタの DNS プレフィックス"
  type        = string
  default     = "nk-aks-1"
}

variable "node_count" {
  type        = number
  description = "The initial quantity of nodes for the node pool."
  default     = 3
}

variable "msi_id" {
  type        = string
  description = "The Managed Service Identity ID. Set this value if you're running this example using Managed Identity as the authentication method."
  default     = null
}

variable "username" {
  type        = string
  description = "The admin username for the new cluster."
  default     = "azureadmin"
}

variable "appgw_subnet_cidr" {
  description = "CIDR for Application Gateway subnet"
  type        = string
  default     = "10.0.2.0/24"  # 仮想ネットワーク内の範囲に変更
}

variable "aks_subnet_cidr" {
  description = "CIDR for AKS subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "service_cidr" {
  description = "CIDR for Kubernetes services"
  type        = string
  default     = "10.0.3.0/24"
}

variable "dns_service_ip" {
  description = "DNS service IP"
  type        = string
  default     = "10.0.3.10"
}
