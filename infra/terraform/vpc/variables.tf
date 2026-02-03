variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "ai-finops"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Project     = "ai-finops"
    Environment = "prod"
    ManagedBy   = "terraform"
    CostCenter  = "engineering"
  }
}