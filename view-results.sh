#!/bin/bash

# Simple script to view AI optimization simulation results
# This provides an alternative to Grafana for viewing results

echo "🔍 AI & Kubernetes Cost Optimization Results Viewer"
echo "=================================================="

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_section() {
    echo -e "\n${BLUE}📊 $1${NC}"
    echo "----------------------------------------"
}

# Function to get AI Gateway metrics
get_ai_metrics() {
    echo "Getting AI Gateway metrics..."
    
    # Port forward in background
    kubectl port-forward service/ai-gateway-service 8080:80 &
    PID=$!
    sleep 3
    
    # Get metrics
    METRICS=$(curl -s http://localhost:8080/metrics 2>/dev/null)
    STATS=$(curl -s http://localhost:8080/stats 2>/dev/null)
    
    # Kill port forward
    kill $PID 2>/dev/null
    wait $PID 2>/dev/null
    
    if [ -n "$METRICS" ]; then
        echo -e "${GREEN}✅ Successfully retrieved AI Gateway metrics${NC}"
        
        # Parse key metrics
        echo "$METRICS" > /tmp/ai_metrics.txt
        echo "$STATS" > /tmp/ai_stats.json
        
        return 0
    else
        echo -e "${RED}❌ Could not retrieve AI Gateway metrics${NC}"
        return 1
    fi
}

# Function to display cost analysis
show_cost_analysis() {
    print_section "Cost Analysis"
    
    if [ -f /tmp/ai_metrics.txt ]; then
        echo "Token Usage by Model:"
        grep "ai_tokens_total" /tmp/ai_metrics.txt | while read line; do
            echo "  $line"
        done
        
        echo ""
        echo "Cost Breakdown by Model:"
        grep "ai_cost_total" /tmp/ai_metrics.txt | while read line; do
            echo "  $line"
        done
        
        echo ""
        echo "Cache Performance:"
        CACHE_HITS=$(grep "ai_cache_hits_total" /tmp/ai_metrics.txt | awk '{print $2}' || echo "0")
        CACHE_MISSES=$(grep "ai_cache_misses_total" /tmp/ai_metrics.txt | awk '{print $2}' || echo "0")
        
        if [ "$CACHE_HITS" != "0" ] || [ "$CACHE_MISSES" != "0" ]; then
            TOTAL_REQUESTS=$((CACHE_HITS + CACHE_MISSES))
            if [ $TOTAL_REQUESTS -gt 0 ]; then
                CACHE_HIT_RATE=$(echo "scale=1; $CACHE_HITS * 100 / $TOTAL_REQUESTS" | bc -l 2>/dev/null || echo "N/A")
                echo "  Cache Hits: $CACHE_HITS"
                echo "  Cache Misses: $CACHE_MISSES"
                echo "  Cache Hit Rate: ${CACHE_HIT_RATE}%"
            fi
        else
            echo "  No cache data available yet"
        fi
    else
        echo "No AI metrics available. Make sure the AI Gateway is running."
    fi
}

# Function to show Kubernetes resource usage
show_k8s_resources() {
    print_section "Kubernetes Resource Usage"
    
    echo "Current Pod Resource Usage:"
    kubectl top pods --no-headers 2>/dev/null | grep -E "(overprovisioned|rightsized|ai-gateway)" || echo "Metrics server not available"
    
    echo ""
    echo "Pod Status:"
    kubectl get pods -o wide | grep -E "(overprovisioned|rightsized|ai-gateway|redis)" || echo "No simulation pods found"
    
    echo ""
    echo "Resource Requests Comparison:"
    echo "Overprovisioned App:"
    kubectl get deployment overprovisioned-app -o jsonpath='{.spec.template.spec.containers[0].resources}' 2>/dev/null | jq . 2>/dev/null || echo "  Not deployed"
    
    echo "Rightsized App:"
    kubectl get deployment rightsized-app -o jsonpath='{.spec.template.spec.containers[0].resources}' 2>/dev/null | jq . 2>/dev/null || echo "  Not deployed"
}

# Function to show job results
show_job_results() {
    print_section "Load Test Results"
    
    echo "Unoptimized Load Test (Phase 1):"
    if kubectl get job ai-load-generator-unoptimized &>/dev/null; then
        echo "Job Status:"
        kubectl get job ai-load-generator-unoptimized
        echo ""
        echo "Last 10 lines of output:"
        kubectl logs job/ai-load-generator-unoptimized --tail=10 2>/dev/null || echo "No logs available"
    else
        echo "  Job not found or not completed"
    fi
    
    echo ""
    echo "Optimized Load Test (Phase 2):"
    if kubectl get job ai-load-generator-optimized-test &>/dev/null; then
        echo "Job Status:"
        kubectl get job ai-load-generator-optimized-test
        echo ""
        echo "Last 10 lines of output:"
        kubectl logs job/ai-load-generator-optimized-test --tail=10 2>/dev/null || echo "No logs available"
    else
        echo "  Job not found or not completed"
    fi
}

# Function to calculate savings
calculate_savings() {
    print_section "Estimated Savings Calculation"
    
    if [ -f /tmp/ai_metrics.txt ]; then
        # Extract total costs
        GPT4_COST=$(grep 'ai_cost_total{model="gpt-4"}' /tmp/ai_metrics.txt | awk '{print $2}' || echo "0")
        GPT35_COST=$(grep 'ai_cost_total{model="gpt-3.5-turbo"}' /tmp/ai_metrics.txt | awk '{print $2}' || echo "0")
        HAIKU_COST=$(grep 'ai_cost_total{model="claude-haiku"}' /tmp/ai_metrics.txt | awk '{print $2}' || echo "0")
        
        TOTAL_AI_COST=$(echo "$GPT4_COST + $GPT35_COST + $HAIKU_COST" | bc -l 2>/dev/null || echo "0")
        
        echo "Current AI Costs:"
        echo "  GPT-4: \$${GPT4_COST}"
        echo "  GPT-3.5-Turbo: \$${GPT35_COST}"
        echo "  Claude Haiku: \$${HAIKU_COST}"
        echo "  Total: \$${TOTAL_AI_COST}"
        
        # Estimate unoptimized cost (if all requests were GPT-4)
        CACHE_HITS=$(grep "ai_cache_hits_total" /tmp/ai_metrics.txt | awk '{print $2}' || echo "0")
        if [ "$CACHE_HITS" != "0" ]; then
            # Rough calculation assuming cache saves 70% of costs
            UNOPTIMIZED_COST=$(echo "$TOTAL_AI_COST / 0.3" | bc -l 2>/dev/null || echo "N/A")
            SAVINGS=$(echo "$UNOPTIMIZED_COST - $TOTAL_AI_COST" | bc -l 2>/dev/null || echo "N/A")
            SAVINGS_PERCENT=$(echo "scale=1; $SAVINGS * 100 / $UNOPTIMIZED_COST" | bc -l 2>/dev/null || echo "N/A")
            
            echo ""
            echo "Estimated Savings:"
            echo "  Without optimization: \$${UNOPTIMIZED_COST}"
            echo "  With optimization: \$${TOTAL_AI_COST}"
            echo "  Savings: \$${SAVINGS} (${SAVINGS_PERCENT}%)"
        fi
    fi
    
    echo ""
    echo "Kubernetes Resource Savings:"
    echo "  Overprovisioned: 1000m CPU, 1Gi RAM"
    echo "  Rightsized: 400m CPU, 400Mi RAM"
    echo "  Savings: 60% CPU, 60% Memory"
}

# Function to show live metrics
show_live_metrics() {
    print_section "Live Metrics (30 seconds)"
    
    echo "Monitoring AI Gateway for 30 seconds..."
    echo "Press Ctrl+C to stop early"
    
    kubectl port-forward service/ai-gateway-service 8080:80 &
    PID=$!
    sleep 2
    
    for i in {1..6}; do
        echo ""
        echo "Sample $i/6 ($(date)):"
        
        ACTIVE_REQUESTS=$(curl -s http://localhost:8080/metrics 2>/dev/null | grep "ai_active_requests" | awk '{print $2}' || echo "0")
        echo "  Active Requests: $ACTIVE_REQUESTS"
        
        sleep 5
    done
    
    kill $PID 2>/dev/null
    wait $PID 2>/dev/null
}

# Main menu
show_menu() {
    echo ""
    echo "Choose an option:"
    echo "1. View Cost Analysis"
    echo "2. View Kubernetes Resources"
    echo "3. View Job Results"
    echo "4. Calculate Savings"
    echo "5. Show Live Metrics"
    echo "6. Full Report"
    echo "7. Export Results"
    echo "0. Exit"
    echo ""
    read -p "Enter your choice (0-7): " choice
    
    case $choice in
        1) get_ai_metrics && show_cost_analysis ;;
        2) show_k8s_resources ;;
        3) show_job_results ;;
        4) get_ai_metrics && calculate_savings ;;
        5) show_live_metrics ;;
        6) 
            get_ai_metrics
            show_cost_analysis
            show_k8s_resources
            show_job_results
            calculate_savings
            ;;
        7) export_results ;;
        0) echo "Goodbye!"; exit 0 ;;
        *) echo "Invalid choice. Please try again." ;;
    esac
}

# Function to export results
export_results() {
    print_section "Exporting Results"
    
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    REPORT_FILE="simulation_results_${TIMESTAMP}.txt"
    
    {
        echo "AI & Kubernetes Cost Optimization Simulation Results"
        echo "Generated: $(date)"
        echo "=================================================="
        echo ""
        
        if get_ai_metrics; then
            echo "COST ANALYSIS:"
            show_cost_analysis
            echo ""
            
            echo "SAVINGS CALCULATION:"
            calculate_savings
            echo ""
        fi
        
        echo "KUBERNETES RESOURCES:"
        show_k8s_resources
        echo ""
        
        echo "JOB RESULTS:"
        show_job_results
        
    } > "$REPORT_FILE"
    
    echo "Results exported to: $REPORT_FILE"
}

# Main execution
main() {
    # Check if kubectl is available
    if ! command -v kubectl &> /dev/null; then
        echo -e "${RED}❌ kubectl is not installed${NC}"
        exit 1
    fi
    
    # Check cluster connection
    if ! kubectl cluster-info &> /dev/null; then
        echo -e "${RED}❌ Cannot connect to Kubernetes cluster${NC}"
        exit 1
    fi
    
    while true; do
        show_menu
        echo ""
        read -p "Press Enter to continue..."
    done
}

# Run main function
main