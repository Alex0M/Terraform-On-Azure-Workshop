variable "env_prefix" {
  description = "The prefix used for all resources"
  default     = "hconf2020"
}

variable "location" {
  description = "the Azure location where all resources will be created"
  default     = "eastus"
}

variable "subscription_id" {
  description = "Azure Subscription ID"
}

variable "branch" {
    description = "The branch name of the repository"
    default     = "master"
}

variable "repo_url" {
    description = "Repository url to pull the latest source from"
    default     = "https://github.com/Alex0M/AzureEats-Website"
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