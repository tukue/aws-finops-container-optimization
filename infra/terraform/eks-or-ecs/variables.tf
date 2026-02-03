variable "orchestrator" {
  description = "Container orchestrator to use (eks or ecs)"
  type        = string
  default     = "eks"
  validation {
    condition     = contains(["eks", "ecs"], var.orchestrator)
    error_message = "Orchestrator must be either 'eks' or 'ecs'."
  }
}

variable "cluster_name" {
  description = "Name of the EKS/ECS cluster"
  type        = string
  default     = "ai-workload-cluster"
}

variable "kubernetes_version" {
  description = "Kubernetes version for EKS"
  type        = string
  default     = "1.28"
}

variable "subnet_ids" {
  description = "List of subnet IDs"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "spot_instance_types" {
  description = "Instance types for spot instances"
  type        = list(string)
  default     = ["c5.large", "c5.xlarge", "m5.large", "m5.xlarge"]
}

variable "spot_desired_size" {
  description = "Desired number of spot instances"
  type        = number
  default     = 2
}

variable "spot_max_size" {
  description = "Maximum number of spot instances"
  type        = number
  default     = 10
}

variable "spot_min_size" {
  description = "Minimum number of spot instances"
  type        = number
  default     = 0
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Project     = "ai-finops"
    Environment = "prod"
    ManagedBy   = "terraform"
  }
}