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