# EKS Cluster (when orchestrator = "eks")
resource "aws_eks_cluster" "main" {
  count = var.orchestrator == "eks" ? 1 : 0

  name     = var.cluster_name
  role_arn = aws_iam_role.cluster[0].arn
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  enabled_cluster_log_types = ["api", "audit"]

  tags = merge(var.common_tags, {
    Name = var.cluster_name
    Type = "eks"
  })
}

# EKS Node Group for Spot Instances
resource "aws_eks_node_group" "spot" {
  count = var.orchestrator == "eks" ? 1 : 0

  cluster_name    = aws_eks_cluster.main[0].name
  node_group_name = "${var.cluster_name}-spot"
  node_role_arn   = aws_iam_role.node[0].arn
  subnet_ids      = var.private_subnet_ids

  capacity_type  = "SPOT"
  instance_types = var.spot_instance_types

  scaling_config {
    desired_size = var.spot_desired_size
    max_size     = var.spot_max_size
    min_size     = var.spot_min_size
  }

  tags = merge(var.common_tags, {
    Name = "${var.cluster_name}-spot-nodes"
    Type = "spot"
  })
}

# ECS Cluster (when orchestrator = "ecs")
resource "aws_ecs_cluster" "main" {
  count = var.orchestrator == "ecs" ? 1 : 0

  name = var.cluster_name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = merge(var.common_tags, {
    Name = var.cluster_name
    Type = "ecs"
  })
}

# ECS Cluster Capacity Providers
resource "aws_ecs_cluster_capacity_providers" "main" {
  count        = var.orchestrator == "ecs" ? 1 : 0
  cluster_name = aws_ecs_cluster.main[0].name

  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 30
    capacity_provider = "FARGATE"
  }

  default_capacity_provider_strategy {
    base              = 0
    weight            = 70
    capacity_provider = "FARGATE_SPOT"
  }
}