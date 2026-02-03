#!/bin/bash
set -e

echo "Testing FinOps Container Optimization Infrastructure"

# Test 1: Terraform validation
echo "1. Validating Terraform configurations..."
cd infra/terraform/vpc && terraform init && terraform validate
cd ../eks-or-ecs && terraform init && terraform validate
cd ../budgets && terraform init && terraform validate
cd ../tagging && terraform init && terraform validate
cd ../../..

# Test 2: Docker builds
echo "2. Testing Docker builds..."
docker build -t inference-api:test services/inference-api/
docker build -t batch-worker:test services/batch-worker/

# Test 3: Service health checks
echo "3. Testing service health..."
docker run -d -p 8000:8000 --name test-api inference-api:test
sleep 5
curl -f http://localhost:8000/health || exit 1
docker stop test-api && docker rm test-api

# Test 4: Kubernetes manifests
echo "4. Validating Kubernetes manifests..."
kubectl --dry-run=client apply -f platform/autoscaling/hpa.yaml
kubectl --dry-run=client apply -f platform/spot-provisioning/karpenter.yaml

echo "All tests passed!"