#!/bin/bash

# AI & Kubernetes Cost Optimization Simulation Test Script
# This script demonstrates the complete optimization workflow

set -e

echo "🚀 Starting AI & Kubernetes Cost Optimization Simulation"
echo "========================================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE=${NAMESPACE:-default}
DOCKER_REGISTRY=${DOCKER_REGISTRY:-localhost:5000}

print_step() {
    echo -e "\n${BLUE}📋 Step: $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Function to wait for deployment to be ready
wait_for_deployment() {
    local deployment=$1
    local namespace=$2
    echo "Waiting for deployment $deployment to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment/$deployment -n $namespace
}

# Function to check if kubectl is available
check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed or not in PATH"
        exit 1
    fi
    
    if ! kubectl cluster-info &> /dev/null; then
        print_error "Cannot connect to Kubernetes cluster"
        exit 1
    fi
    
    print_success "Kubernetes cluster connection verified"
}

# Function to build and push Docker images
build_and_push_images() {
    print_step "Building and pushing Docker images"
    
    # Build AI Gateway Mock
    echo "Building ai-gateway-mock..."
    docker build -t $DOCKER_REGISTRY/ai-gateway-mock:latest services/ai-gateway-mock/
    docker push $DOCKER_REGISTRY/ai-gateway-mock:latest
    
    # Build AI Load Generator
    echo "Building ai-load-generator..."
    docker build -t $DOCKER_REGISTRY/ai-load-generator:latest services/ai-load-generator/
    docker push $DOCKER_REGISTRY/ai-load-generator:latest
    
    print_success "Docker images built and pushed"
}

# Function to deploy Phase 1 - Unoptimized state
deploy_phase1() {
    print_step "Phase 1: Deploying Unoptimized State"
    
    # Deploy overprovisioned app
    kubectl apply -f platform/optimization-simulation/overprovisioned-app.yaml
    
    # Deploy AI Gateway (without optimization)
    sed "s|ai-gateway-mock:latest|$DOCKER_REGISTRY/ai-gateway-mock:latest|g" platform/ai-gateway/ai-gateway.yaml | kubectl apply -f -
    
    # Wait for deployments
    wait_for_deployment "overprovisioned-app" $NAMESPACE
    wait_for_deployment "ai-gateway-mock" $NAMESPACE
    wait_for_deployment "redis" $NAMESPACE
    
    print_success "Phase 1 deployments ready"
}

# Function to run unoptimized load test
run_unoptimized_load() {
    print_step "Running Unoptimized Load Test (5 minutes)"
    
    # Update load generator image in job manifest and apply
    sed "s|ai-load-generator:latest|$DOCKER_REGISTRY/ai-load-generator:latest|g" platform/ai-load-generator/load-generator.yaml | \
    kubectl apply -f -
    
    # Wait for job to complete
    echo "Running unoptimized load for 5 minutes..."
    kubectl wait --for=condition=complete --timeout=400s job/ai-load-generator-unoptimized
    
    # Show results
    echo "Unoptimized load test results:"
    kubectl logs job/ai-load-generator-unoptimized
    
    print_success "Unoptimized load test completed"
}

# Function to collect Phase 1 metrics
collect_phase1_metrics() {
    print_step "Collecting Phase 1 Metrics"
    
    echo "Getting AI Gateway metrics..."
    kubectl port-forward service/ai-gateway-service 8080:80 &
    PORT_FORWARD_PID=$!
    sleep 5
    
    curl -s http://localhost:8080/metrics | grep -E "(ai_cost_total|ai_tokens_total|ai_cache)" || true
    curl -s http://localhost:8080/stats || true
    
    kill $PORT_FORWARD_PID 2>/dev/null || true
    
    echo "Getting Kubernetes resource usage..."
    kubectl top pods --no-headers | head -10 || print_warning "Metrics server not available"
    
    print_success "Phase 1 metrics collected"
}

# Function to deploy Phase 2 - Optimized state
deploy_phase2() {
    print_step "Phase 2: Applying Optimizations"
    
    # Apply rightsized app
    kubectl apply -f platform/optimization-simulation/rightsized-app.yaml
    
    # The AI Gateway already supports caching, optimization happens through load pattern
    
    # Wait for rightsized deployment
    wait_for_deployment "rightsized-app" $NAMESPACE
    
    print_success "Phase 2 optimizations applied"
}

# Function to run optimized load test
run_optimized_load() {
    print_step "Running Optimized Load Test (5 minutes)"
    
    # Delete previous job and run optimized version
    kubectl delete job ai-load-generator-unoptimized --ignore-not-found=true
    
    # Wait a moment for cleanup
    sleep 10
    
    # Run optimized load test
    kubectl create job ai-load-generator-optimized-test --from=job/ai-load-generator-optimized
    
    # Wait for job to complete
    echo "Running optimized load for 5 minutes..."
    kubectl wait --for=condition=complete --timeout=400s job/ai-load-generator-optimized-test
    
    # Show results
    echo "Optimized load test results:"
    kubectl logs job/ai-load-generator-optimized-test
    
    print_success "Optimized load test completed"
}

# Function to collect Phase 2 metrics
collect_phase2_metrics() {
    print_step "Collecting Phase 2 Metrics"
    
    echo "Getting AI Gateway metrics after optimization..."
    kubectl port-forward service/ai-gateway-service 8080:80 &
    PORT_FORWARD_PID=$!
    sleep 5
    
    curl -s http://localhost:8080/metrics | grep -E "(ai_cost_total|ai_tokens_total|ai_cache)" || true
    curl -s http://localhost:8080/stats || true
    
    kill $PORT_FORWARD_PID 2>/dev/null || true
    
    echo "Getting optimized Kubernetes resource usage..."
    kubectl top pods --no-headers | head -10 || print_warning "Metrics server not available"
    
    print_success "Phase 2 metrics collected"
}

# Function to generate comparison report
generate_report() {
    print_step "Generating Optimization Report"
    
    cat << EOF

🎯 AI & Kubernetes Cost Optimization Results
============================================

Phase 1 (Unoptimized):
- Over-provisioned Kubernetes pods
- AI requests using expensive models (GPT-4)
- No caching enabled
- High token consumption

Phase 2 (Optimized):
- Right-sized Kubernetes pods (60% resource reduction)
- Mixed AI model routing (GPT-4: 30%, GPT-3.5: 50%, Claude Haiku: 20%)
- Caching enabled (70% cache hit rate expected)
- Significant cost reduction

Expected Savings:
- Kubernetes compute: ~40% reduction
- AI token costs: ~60% reduction
- Total infrastructure: ~50% cost savings

Next Steps:
1. Monitor Grafana dashboard for real-time metrics
2. Enable Karpenter for spot instance usage
3. Implement automated scaling policies
4. Set up cost alerts and budgets

EOF

    print_success "Optimization simulation completed successfully!"
}

# Function to setup monitoring
setup_monitoring() {
    print_step "Setting up Monitoring"
    
    # Apply Grafana configuration
    kubectl apply -f platform/grafana/grafana.yaml
    
    # Wait for Grafana to be ready
    wait_for_deployment "grafana" $NAMESPACE
    
    echo "Grafana dashboard available at: http://localhost:3000"
    echo "Default credentials: admin/admin"
    
    print_success "Monitoring setup completed"
}

# Function to cleanup
cleanup() {
    print_step "Cleaning up resources"
    
    kubectl delete job ai-load-generator-unoptimized --ignore-not-found=true
    kubectl delete job ai-load-generator-optimized-test --ignore-not-found=true
    kubectl delete -f platform/ai-gateway/ai-gateway.yaml --ignore-not-found=true
    kubectl delete -f platform/optimization-simulation/overprovisioned-app.yaml --ignore-not-found=true
    kubectl delete -f platform/optimization-simulation/rightsized-app.yaml --ignore-not-found=true
    
    print_success "Cleanup completed"
}

# Main execution flow
main() {
    echo "Starting AI & Kubernetes Cost Optimization Simulation"
    echo "Namespace: $NAMESPACE"
    echo "Docker Registry: $DOCKER_REGISTRY"
    echo ""
    
    # Check prerequisites
    check_kubectl
    
    # Handle command line arguments
    case "${1:-all}" in
        "build")
            build_and_push_images
            ;;
        "phase1")
            deploy_phase1
            run_unoptimized_load
            collect_phase1_metrics
            ;;
        "phase2")
            deploy_phase2
            run_optimized_load
            collect_phase2_metrics
            ;;
        "monitoring")
            setup_monitoring
            ;;
        "cleanup")
            cleanup
            ;;
        "all")
            build_and_push_images
            deploy_phase1
            run_unoptimized_load
            collect_phase1_metrics
            deploy_phase2
            run_optimized_load
            collect_phase2_metrics
            generate_report
            setup_monitoring
            ;;
        *)
            echo "Usage: $0 [build|phase1|phase2|monitoring|cleanup|all]"
            echo ""
            echo "Commands:"
            echo "  build      - Build and push Docker images"
            echo "  phase1     - Deploy and test unoptimized state"
            echo "  phase2     - Deploy and test optimized state"
            echo "  monitoring - Setup Grafana monitoring"
            echo "  cleanup    - Remove all deployed resources"
            echo "  all        - Run complete simulation (default)"
            exit 1
            ;;
    esac
}

# Trap to cleanup on exit
trap cleanup EXIT

# Run main function
main "$@"