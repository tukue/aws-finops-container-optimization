#!/bin/bash

# Validation script for AI & Kubernetes Cost Optimization Simulation
# This script checks if all components are properly set up

set -e

echo "🔍 Validating AI & Kubernetes Cost Optimization Setup"
echo "===================================================="

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

ERRORS=0

check_file() {
    if [ -f "$1" ]; then
        echo -e "${GREEN}✅ Found: $1${NC}"
    else
        echo -e "${RED}❌ Missing: $1${NC}"
        ((ERRORS++))
    fi
}

check_directory() {
    if [ -d "$1" ]; then
        echo -e "${GREEN}✅ Directory: $1${NC}"
    else
        echo -e "${RED}❌ Missing directory: $1${NC}"
        ((ERRORS++))
    fi
}

echo "Checking core components..."

# Check AI Gateway Mock
check_directory "services/ai-gateway-mock"
check_file "services/ai-gateway-mock/Dockerfile"
check_file "services/ai-gateway-mock/main.py"
check_file "services/ai-gateway-mock/requirements.txt"

# Check AI Load Generator
check_directory "services/ai-load-generator"
check_file "services/ai-load-generator/Dockerfile"
check_file "services/ai-load-generator/load_generator.py"
check_file "services/ai-load-generator/requirements.txt"

# Check Kubernetes manifests
check_directory "platform/ai-gateway"
check_file "platform/ai-gateway/ai-gateway.yaml"
check_directory "platform/ai-load-generator"
check_file "platform/ai-load-generator/load-generator.yaml"

# Check existing optimization components
check_file "platform/optimization-simulation/overprovisioned-app.yaml"
check_file "platform/optimization-simulation/rightsized-app.yaml"

# Check Grafana dashboard
check_file "platform/grafana/finops-dashboard.json"
check_file "platform/grafana/grafana.yaml"

# Check test scripts
check_file "test-ai-optimization.sh"
check_file "test-ai-optimization.bat"

# Check documentation
check_file "AI-OPTIMIZATION-README.md"
check_file "docs/ai-optimization-design.md"

echo ""
echo "Checking prerequisites..."

# Check kubectl
if command -v kubectl &> /dev/null; then
    echo -e "${GREEN}✅ kubectl is installed${NC}"
    if kubectl cluster-info &> /dev/null; then
        echo -e "${GREEN}✅ kubectl can connect to cluster${NC}"
    else
        echo -e "${YELLOW}⚠️  kubectl cannot connect to cluster (this is OK if not running yet)${NC}"
    fi
else
    echo -e "${RED}❌ kubectl is not installed${NC}"
    ((ERRORS++))
fi

# Check docker
if command -v docker &> /dev/null; then
    echo -e "${GREEN}✅ Docker is installed${NC}"
else
    echo -e "${RED}❌ Docker is not installed${NC}"
    ((ERRORS++))
fi

echo ""
echo "Validation Summary:"
echo "=================="

if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}🎉 All components are properly set up!${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Ensure your Kubernetes cluster is running"
    echo "2. Configure your Docker registry (if needed)"
    echo "3. Run: ./test-ai-optimization.sh all"
    echo ""
    echo "For detailed instructions, see: AI-OPTIMIZATION-README.md"
else
    echo -e "${RED}❌ Found $ERRORS issues that need to be resolved${NC}"
    exit 1
fi