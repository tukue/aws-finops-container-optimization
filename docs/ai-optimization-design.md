# Design Document: AI & Kubernetes Cost Optimization Simulation

## 1. Objective
To design a comprehensive simulation environment that demonstrates FinOps principles for both traditional Kubernetes workloads (compute/memory) and modern AI workloads (token usage/API calls). This simulation will use provisioned cloud resources to provide a realistic "Consulting" demonstration.

## 2. Scope
The simulation will cover two distinct cost vectors:
1.  **Infrastructure Costs**: EKS Node scaling, Pod rightsizing, and Spot instance usage.
2.  **AI/LLM Costs**: Token consumption (Input/Output), Model selection, and API throughput.

## 3. Architecture Overview

### 3.1 Infrastructure Layer (Existing)
*   **EKS Cluster**: The foundation for running workloads.
*   **Karpenter**: For node autoscaling and Spot instance provisioning.
*   **Kubecost**: For pod-level cost attribution.

### 3.2 AI Simulation Layer (New)
To simulate AI costs without incurring massive bills from OpenAI/Anthropic, we will deploy:
*   **AI Gateway (Mock)**: A lightweight proxy service deployed on EKS.
    *   **Function**: Intercepts requests, counts "tokens", and simulates latency based on model type.
    *   **Metrics**: Exposes Prometheus metrics for `ai_input_tokens`, `ai_output_tokens`, and `ai_estimated_cost`.
*   **Load Generator**: A cron job or deployment that sends synthetic prompts to the AI Gateway.

## 4. Optimization Strategies to Demonstrate

### 4.1 Kubernetes Optimization (The "Compute" Vector)
*   **Problem**: Over-provisioned microservices wasting CPU/RAM.
*   **Solution**:
    *   **Rightsizing**: Adjusting `requests` and `limits` based on historical usage.
    *   **Spot Integration**: Moving stateless pods to Spot instances via Karpenter.

### 4.2 AI Optimization (The "Token" Vector)
*   **Problem**: Inefficient prompt engineering, redundant queries, and using expensive models for simple tasks.
*   **Solution**:
    *   **Semantic Caching**: Serving cached responses for repeated queries to save tokens.
    *   **Model Routing**: Dynamically routing simple queries to cheaper, smaller models (e.g., "Haiku" vs "Opus").
    *   **Token Rate Limiting**: Enforcing budgets per team/project.

## 5. Simulation Workflow

### Phase 1: The "Unoptimized" State
1.  **Deploy Infrastructure**: EKS cluster with On-Demand nodes.
2.  **Deploy Workloads**:
    *   `legacy-app`: Over-provisioned Nginx deployment.
    *   `ai-service`: Simulates usage of "GPT-4" (High cost per token) with no caching.
3.  **Generate Load**: High volume of redundant requests.
4.  **Observe**:
    *   Grafana shows high "Forecasted Cost".
    *   Token usage is linear with request count.

### Phase 2: The "Optimized" State
1.  **Apply K8s Fixes**:
    *   Apply `rightsized-app.yaml`.
    *   Enable Karpenter Spot provisioners.
2.  **Apply AI Fixes**:
    *   Enable **Caching** in the AI Gateway (simulated drop in backend calls).
    *   Switch model config to "Mixed" (routing 50% traffic to cheaper model).
3.  **Observe**:
    *   Compute costs drop by ~40%.
    *   AI Token costs drop by ~60% due to caching and routing.

## 6. Observability & Reporting
*   **Grafana Dashboard Updates**:
    *   Add "AI Token Cost" panel.
    *   Add "Cache Hit Ratio" panel.
    *   Add "Model Distribution" pie chart.

## 7. Implementation Plan
1.  **Terraform**: Provision EKS (User to run).
2.  **Development**: Build the `ai-gateway-mock` container (Python/FastAPI).
3.  **Manifests**: Create K8s deployments for the gateway and load generator.
4.  **Dashboards**: Update Grafana JSON to consume new AI metrics.
