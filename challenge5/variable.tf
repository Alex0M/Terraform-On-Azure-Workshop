variable "client_id" {}
variable "client_secret" {}

variable "env_prefix" {
  description = "The prefix used for all resources"
}

variable "location" {
  description = "the Azure location where all resources will be created"
  default     = "eastus"
}

variable "sqlserver_login" {
    description = "The name of the Azure SQL Server Admin user"
}

variable "sqlserver_pass" {
    description = "The Azure SQL Database Admin users password"
}

variable "mongo_root_user" {
    description = "The name of the MangoDB Root user"
}

variable "mongo_root_pass" {
    description = "The MongoDB Root user password"
}

variable "k8s_node_count" {
    description = "The initial number of nodes which should exist in AKS"
    default = 1
}

variable "k8s_vm_size" {
    description = "The size of the Virtual Machine"
    default = "Standard_D2_v2"
}

variable "k8s_ssh_public_key" {
    default = "~/.ssh/id_rsa.pub"
}