variable "env_prefix" {
  description = "The prefix used for all resources"
}

variable "location" {
  description = "the Azure location where all resources will be created"
  default     = "eastus"
}

variable "k8s_node_count" {
    description = "The initial number of nodes which should exist in AKS"
    default = 1
}

variable "k8s_vm_size" {
    description = "The size of the Virtual Machine"
    default = "Standard_D2_v2"
}