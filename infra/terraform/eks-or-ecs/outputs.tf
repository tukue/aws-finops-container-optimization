output "cluster_name" {
  description = "Name of the EKS/ECS cluster"
  value       = var.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint for EKS cluster (null for ECS)"
  value       = var.orchestrator == "eks" ? aws_eks_cluster.main[0].endpoint : null
}

output "cluster_arn" {
  description = "ARN of the EKS/ECS cluster"
  value       = var.orchestrator == "eks" ? aws_eks_cluster.main[0].arn : aws_ecs_cluster.main[0].arn
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster (null for ECS)"
  value       = var.orchestrator == "eks" ? aws_eks_cluster.main[0].vpc_config[0].cluster_security_group_id : null
}

output "orchestrator_type" {
  description = "Type of container orchestrator deployed"
  value       = var.orchestrator
}

output "node_role_arn" {
  description = "ARN of the EKS node IAM role (null for ECS)"
  value       = var.orchestrator == "eks" ? aws_iam_role.node[0].arn : null
}

output "task_execution_role_arn" {
  description = "ARN of the ECS task execution IAM role (null for EKS)"
  value       = var.orchestrator == "ecs" ? aws_iam_role.ecs_task_execution[0].arn : null
}