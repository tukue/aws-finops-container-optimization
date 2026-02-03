terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.100"
    }
  }
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "ai-finops"
}

variable "monthly_budget_limit" {
  description = "Monthly budget limit in USD"
  type        = string
  default     = "1000"
}

variable "compute_budget_limit" {
  description = "Compute budget limit in USD"
  type        = string
  default     = "600"
}

variable "storage_budget_limit" {
  description = "Storage budget limit in USD"
  type        = string
  default     = "200"
}

variable "budget_alert_emails" {
  description = "List of email addresses for budget alerts"
  type        = list(string)
  default     = ["admin@example.com"]
}