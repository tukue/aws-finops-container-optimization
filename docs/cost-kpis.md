# Cost KPIs for AI Container Workloads

## Overview

Key Performance Indicators (KPIs) for measuring FinOps success in AI containerized workloads on AWS ECS/EKS.

## Primary Cost KPIs

### 1. Cost Efficiency Metrics

#### Cost per Model Training
```
Formula: Total Training Cost / Number of Models Trained
Target: <$500 per model (varies by complexity)
Frequency: Weekly
```

#### Cost per Inference Request
```
Formula: Total Inference Cost / Number of Requests
Target: <$0.001 per request
Frequency: Daily
```

#### GPU Utilization Rate
```
Formula: (GPU Hours Used / GPU Hours Provisioned) × 100
Target: >80%
Frequency: Real-time
```

### 2. Resource Optimization KPIs

#### Spot Instance Adoption
```
Formula: (Spot Instance Hours / Total Instance Hours) × 100
Target: >70% for training, >50% for inference
Frequency: Daily
```

#### Right-sizing Efficiency
```
Formula: (Actual Resource Usage / Provisioned Resources) × 100
Target: >75% CPU, >70% Memory
Frequency: Weekly
```

#### Idle Resource Cost
```
Formula: Cost of Resources with <20% Utilization
Target: <5% of total compute cost
Frequency: Daily
```

## Secondary Cost KPIs

### 3. Storage Optimization

#### Storage Cost per GB
```
Formula: Total Storage Cost / Total GB Stored
Target: Varies by storage class
Frequency: Monthly
```

#### Data Lifecycle Efficiency
```
Formula: (Cold Storage GB / Total Storage GB) × 100
Target: >60% for archived data
Frequency: Monthly
```

### 4. Network Optimization

#### Data Transfer Cost Ratio
```
Formula: (Data Transfer Cost / Total Cost) × 100
Target: <10%
Frequency: Monthly
```

## Business Impact KPIs

### 5. Financial Performance

#### Cost Reduction Rate
```
Formula: ((Previous Period Cost - Current Period Cost) / Previous Period Cost) × 100
Target: 5-10% quarterly improvement
Frequency: Quarterly
```

#### ROI on FinOps Investment
```
Formula: (Cost Savings - FinOps Investment) / FinOps Investment × 100
Target: >300% annually
Frequency: Quarterly
```

#### Budget Variance
```
Formula: ((Actual Spend - Budgeted Spend) / Budgeted Spend) × 100
Target: ±5%
Frequency: Monthly
```

### 6. Operational Efficiency

#### Mean Time to Optimize (MTTO)
```
Formula: Average time from cost anomaly detection to resolution
Target: <24 hours
Frequency: Monthly
```

#### Automation Rate
```
Formula: (Automated Optimizations / Total Optimizations) × 100
Target: >90%
Frequency: Monthly
```

## KPI Dashboard Structure

### Executive Dashboard
- Total monthly spend trend
- Cost reduction percentage
- Budget vs actual
- ROI metrics

### Engineering Dashboard
- Resource utilization rates
- Spot instance savings
- Right-sizing opportunities
- Performance impact metrics

### Team Scorecards
- Cost per team/project
- Efficiency rankings
- Optimization achievements
- Target vs actual performance

## Alerting Thresholds

### Critical Alerts
- Daily spend >150% of average
- GPU utilization <50% for >2 hours
- Budget 90% consumed

### Warning Alerts
- Weekly spend >120% of average
- Spot instance usage <target
- Storage growth >20% monthly

### Info Alerts
- New optimization opportunities
- Monthly KPI reports
- Benchmark comparisons

## Measurement Tools

### AWS Native
- Cost Explorer for cost analysis
- CloudWatch for utilization metrics
- Budgets for spend tracking

### Third-party
- Kubecost for Kubernetes cost allocation
- Grafana for custom dashboards
- DataDog for comprehensive monitoring

## Reporting Schedule

### Daily
- Cost and utilization alerts
- Spot instance performance
- Resource right-sizing opportunities

### Weekly
- Team cost scorecards
- Optimization impact reports
- Trend analysis

### Monthly
- Executive KPI dashboard
- Budget variance reports
- ROI calculations

### Quarterly
- Strategic review and planning
- Benchmark comparisons
- Target adjustments

## Success Criteria

### Year 1 Targets
- 30% cost reduction
- 80% GPU utilization
- 70% spot instance adoption
- <5% budget variance

### Ongoing Targets
- 5% quarterly cost improvement
- >90% automation rate
- <24h optimization response time
- >95% SLA compliance