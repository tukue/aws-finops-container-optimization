# AI & Kubernetes Cost Optimization Simulation

This simulation demonstrates FinOps principles for both traditional Kubernetes workloads and modern AI workloads, showing how to achieve significant cost savings through optimization strategies.

## 🎯 Objectives

- Demonstrate **Kubernetes cost optimization** through rightsizing and spot instances
- Show **AI cost optimization** through caching, model routing, and token management
- Provide realistic cost metrics and savings calculations
- Create a comprehensive FinOps demonstration environment

## 🏗️ Architecture

### Infrastructure Layer
- **EKS Cluster**: Foundation for running workloads
- **Karpenter**: Node autoscaling and spot instance provisioning
- **Kubecost**: Pod-level cost attribution

### AI Simulation Layer
- **AI Gateway Mock**: Lightweight proxy that simulates AI API calls
- **Load Generator**: Creates realistic AI workload patterns
- **Redis Cache**: Demonstrates caching impact on costs
- **Prometheus Metrics**: Tracks tokens, costs, and cache performance

## 📊 Optimization Strategies Demonstrated

### Kubernetes Optimization (Compute Vector)
- **Problem**: Over-provisioned microservices wasting CPU/RAM
- **Solutions**:
  - Rightsizing: Adjusting requests/limits based on usage
  - Spot Integration: Moving stateless pods to spot instances
  - **Expected Savings**: ~40% compute cost reduction

### AI Optimization (Token Vector)
- **Problem**: Inefficient AI usage, expensive models, no caching
- **Solutions**:
  - Semantic Caching: Serving cached responses for repeated queries
  - Model Routing: Using cheaper models for simple tasks
  - Token Rate Limiting: Budget enforcement per team/project
  - **Expected Savings**: ~60% AI cost reduction

## 🚀 Quick Start

### Prerequisites
- Kubernetes cluster (EKS, local, or any K8s)
- Docker registry access
- kubectl configured
- Docker installed

### Option 1: Complete Simulation (Recommended)
```bash
# Linux/Mac
chmod +x test-ai-optimization.sh
./test-ai-optimization.sh all

# Windows
test-ai-optimization.bat all
```

### Option 2: Step-by-Step Execution
```bash
# 1. Build and push images
./test-ai-optimization.sh build

# 2. Run Phase 1 (Unoptimized)
./test-ai-optimization.sh phase1

# 3. Run Phase 2 (Optimized)
./test-ai-optimization.sh phase2

# 4. Setup monitoring
./test-ai-optimization.sh monitoring

# 5. Cleanup when done
./test-ai-optimization.sh cleanup
```

## 📈 What You'll See

### Phase 1: Unoptimized State
- Over-provisioned pods consuming excess resources
- AI requests using expensive GPT-4 model exclusively
- No caching - every request hits the "API"
- High token consumption and costs

### Phase 2: Optimized State
- Right-sized pods with 60% resource reduction
- Mixed model routing:
  - GPT-4: 30% (complex queries)
  - GPT-3.5-Turbo: 50% (standard queries)
  - Claude Haiku: 20% (simple queries)
- 70% cache hit rate reducing API calls
- Significant cost reduction

### Expected Results
```
Cost Optimization Results:
├── Kubernetes Compute: 40% reduction
├── AI Token Costs: 60% reduction
└── Total Infrastructure: 50% savings
```

## 🔧 Components

### AI Gateway Mock (`services/ai-gateway-mock/`)
- FastAPI service simulating OpenAI/Anthropic APIs
- Token counting and cost calculation
- Configurable caching with Redis
- Prometheus metrics export
- Multiple model support with different pricing

### Load Generator (`services/ai-load-generator/`)
- Generates realistic AI workload patterns
- Configurable request rates and model distributions
- Simulates duplicate queries for cache testing
- Provides detailed statistics

### Kubernetes Manifests (`platform/`)
- **ai-gateway/**: AI Gateway and Redis deployment
- **ai-load-generator/**: Load testing jobs
- **optimization-simulation/**: Before/after app configurations
- **grafana/**: Enhanced dashboard with AI metrics

## 📊 Monitoring & Observability

### Grafana Dashboard
Access at `http://localhost:3000` (admin/admin)

**New AI Panels Added:**
- AI Token Cost (Hourly)
- AI Cache Hit Ratio
- AI Model Distribution
- AI Tokens per Hour
- Active AI Requests
- AI Cost Savings (Cache Impact)

### Prometheus Metrics
```
# AI Gateway Metrics
ai_tokens_total{type="input|output", model="gpt-4|gpt-3.5-turbo|claude-haiku"}
ai_cost_total{model="gpt-4|gpt-3.5-turbo|claude-haiku"}
ai_request_duration_seconds{model="..."}
ai_cache_hits_total
ai_cache_misses_total
ai_active_requests
```

## 🎛️ Configuration

### Environment Variables
```bash
# Kubernetes namespace
export NAMESPACE=default

# Docker registry for images
export DOCKER_REGISTRY=localhost:5000

# Load test duration
export DURATION_MINUTES=30
```

### Model Configurations
Edit `services/ai-gateway-mock/main.py` to adjust:
- Model pricing (cost per 1K tokens)
- Latency simulation
- Token processing rates

### Load Patterns
Edit `services/ai-load-generator/load_generator.py` to modify:
- Request rates
- Model distributions
- Cache settings
- Duplicate rates

## 🔍 Troubleshooting

### Common Issues

**Images not found:**
```bash
# Ensure images are built and pushed
./test-ai-optimization.sh build
```

**Pods not starting:**
```bash
# Check pod status
kubectl get pods
kubectl describe pod <pod-name>
```

**Metrics not showing:**
```bash
# Verify AI Gateway is running
kubectl port-forward service/ai-gateway-service 8080:80
curl http://localhost:8080/health
curl http://localhost:8080/metrics
```

**Load generator failing:**
```bash
# Check job logs
kubectl logs job/ai-load-generator-unoptimized
```

### Debug Commands
```bash
# Check all resources
kubectl get all -l component=ai-simulation

# View AI Gateway logs
kubectl logs deployment/ai-gateway-mock

# Check Redis connectivity
kubectl exec -it deployment/redis -- redis-cli ping

# Port forward for direct testing
kubectl port-forward service/ai-gateway-service 8080:80
```

## 📚 Understanding the Simulation

### Cost Calculations
The AI Gateway Mock uses realistic pricing:
- **GPT-4**: $0.03/1K input, $0.06/1K output tokens
- **GPT-3.5-Turbo**: $0.001/1K input, $0.002/1K output tokens
- **Claude Haiku**: $0.00025/1K input, $0.00125/1K output tokens

### Cache Impact
- Without cache: Every request = API call + cost
- With cache: 70% requests served from cache = 70% cost reduction
- Cache hit simulation shows dramatic cost savings

### Kubernetes Rightsizing
- **Overprovisioned**: 1000m CPU, 1Gi RAM requests
- **Rightsized**: 400m CPU, 400Mi RAM requests
- **Savings**: 60% resource reduction = 60% compute cost reduction

## 🎯 Business Value

### Demonstration Points
1. **Immediate Impact**: Show 50% cost reduction in minutes
2. **Realistic Metrics**: Based on actual cloud pricing
3. **Scalable Patterns**: Techniques apply to production workloads
4. **Comprehensive View**: Both infrastructure and AI costs

### Consulting Talking Points
- "This simulation shows how we reduced a client's AI costs by 60%"
- "Kubernetes rightsizing alone saved 40% on compute"
- "Caching strategies eliminated 70% of unnecessary API calls"
- "Combined optimizations delivered 50% total infrastructure savings"

## 🔄 Next Steps

### Production Implementation
1. **Assessment**: Analyze current workload patterns
2. **Rightsizing**: Implement resource recommendations
3. **Caching**: Deploy semantic caching for AI workloads
4. **Model Routing**: Implement intelligent model selection
5. **Monitoring**: Set up comprehensive cost tracking
6. **Automation**: Implement continuous optimization

### Advanced Features
- **Spot Instance Integration**: Add Karpenter spot provisioning
- **Auto-scaling**: Implement HPA and VPA
- **Cost Alerts**: Set up budget notifications
- **Multi-cloud**: Extend to Azure/GCP scenarios

## 📞 Support

For questions or issues:
1. Check the troubleshooting section above
2. Review component logs with kubectl
3. Verify all prerequisites are met
4. Test individual components separately

---

**Ready to demonstrate FinOps excellence!** 🚀