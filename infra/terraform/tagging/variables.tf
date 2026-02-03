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

variable "enable_org_policy" {
  description = "Enable organization-level tagging policy"
  type        = bool
  default     = false
}

variable "allowed_teams" {
  description = "List of allowed team names"
  type        = list(string)
  default     = ["ml-platform", "data-science", "ai-research"]
}

variable "allowed_cost_centers" {
  description = "List of allowed cost centers"
  type        = list(string)
  default     = ["engineering", "research", "product"]
}

variable "default_tags" {
  description = "Default tags for resources"
  type        = map(string)
  default = {
    Project     = "ai-finops"
    Environment = "prod"
    ManagedBy   = "terraform"
  }
}