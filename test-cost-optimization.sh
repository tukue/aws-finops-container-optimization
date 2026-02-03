#!/bin/bash
set -e

echo "Testing Cost Optimization Features"

# Test spot instance savings
test_spot_savings() {
    echo "Testing spot instance configuration..."
    
    # Check if spot instances are configured
    if grep -q "SPOT" infra/terraform/eks-or-ecs/*.tf; then
        echo "✓ Spot instances configured"
    else
        echo "✗ Spot instances not found"
        exit 1
    fi
}

# Test autoscaling configuration
test_autoscaling() {
    echo "Testing autoscaling policies..."
    
    # Validate HPA configuration
    kubectl --dry-run=client apply -f platform/autoscaling/hpa.yaml
    echo "✓ HPA configuration valid"
}

# Test budget alerts
test_budgets() {
    echo "Testing budget configuration..."
    
    if grep -q "aws_budgets_budget" infra/terraform/budgets/*.tf; then
        echo "✓ Budget alerts configured"
    else
        echo "✗ Budget configuration missing"
        exit 1
    fi
}

# Test tagging for cost allocation
test_tagging() {
    echo "Testing cost allocation tags..."
    
    if grep -q "Project\|Environment\|Team\|CostCenter" infra/terraform/tagging/*.tf; then
        echo "✓ Cost allocation tags configured"
    else
        echo "✗ Cost allocation tags missing"
        exit 1
    fi
}

# Run all tests
test_spot_savings
test_autoscaling
test_budgets
test_tagging

echo "Cost optimization tests passed!"