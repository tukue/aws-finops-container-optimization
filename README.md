# FinOps Consulting Project: A Blueprint for Cloud Cost Optimization

This project provides a comprehensive, consulting-grade blueprint for establishing a robust FinOps practice on AWS, with a focus on Kubernetes environments. It is designed to be a deployable reference architecture that demonstrates how to achieve full-spectrum cost visibility, implement continuous optimization, and enforce financial governance.

## The Business Problem

Many organizations are struggling with rising and unpredictable cloud costs, especially in complex containerized environments. Without proper visibility and control, it is difficult to attribute costs to the teams that incur them, identify waste, and make data-driven decisions to optimize spending. This leads to budget overruns, reduced profitability, and an inability to maximize the value of the cloud.

## Solution Overview: The Cloud Cost Hub

This project provides a holistic solution built on the three pillars of FinOps: **Inform, Optimize, and Operate**. It establishes a **"Cloud Cost Hub"** using a combination of open-source tools and AWS services to create a single source of truth for cloud financial management.

### Architecture

The architecture is centered around an Amazon EKS cluster, with the following key components:

- **Kubecost**: For granular Kubernetes cost monitoring, allocation, and rightsizing recommendations.
- **Prometheus**: As the time-series database backend for Kubecost.
- **Grafana**: For unified cost visualization, creating a "single pane of glass" for all cost data.
- **AWS Cost Explorer & Budgets**: For high-level AWS account cost data and budget tracking.
- **Terraform**: For deploying and managing all infrastructure as code (IaC).
- **GitHub Actions**: For CI/CD and automated security scanning.

## Key Features

### 1. Inform: Gaining Full-Spectrum Visibility

The foundation of FinOps is visibility. The **Cloud Cost Hub** dashboard in Grafana provides a comprehensive view of all cloud costs:

- **High-Level AWS Costs**:
  - Forecasted Monthly AWS Cost
  - Month-to-Date AWS Cost
  - Daily AWS Cost Trends
- **Granular Kubernetes Costs**:
  - **Showback/Chargeback**: Costs are allocated by `namespace`, `team`, and `project` using Kubernetes labels, enabling true cost attribution.
  - **Cost by Namespace**: Identify which applications and services are driving costs.
  - **Cost by Team**: Attribute costs to the teams responsible for them.

### 2. Optimize: Maximizing Cloud Value

This project includes several features to help you optimize your cloud spend:

- **Spot Instance Automation**: The EKS cluster is configured to use **Karpenter** for intelligent, just-in-time provisioning of Spot instances, which can reduce compute costs by up to 90%.
- **Container Rightsizing**: Kubecost provides recommendations for container CPU and memory requests, helping to eliminate waste from over-provisioned resources.
- **Future Enhancements**:
  - **Automated Idle Resource Cleanup**: Scripts to identify and remove unused resources like EBS volumes and load balancers.
  - **Savings Plan Strategy**: A framework for purchasing AWS Savings Plans for baseline workloads to maximize commitment discounts.

### 3. Operate: Automating Governance & Control

To ensure that costs are managed proactively, this project includes several governance features:

- **Policy as Code**: The CI/CD pipeline includes security scanning with **Trivy** and **Terrascan** to identify vulnerabilities and misconfigurations before they are deployed.
- **Budget Monitoring**: AWS Budgets are used to track spending against targets and can be configured to trigger alerts when thresholds are breached.
- **Future Enhancements**:
  - **Cost Governance with OPA**: Use Open Policy Agent (OPA) to enforce cost-related policies, such as requiring cost-center tags or restricting expensive instance types.
  - **Budget Enforcement Actions**: Configure AWS Budgets to automatically trigger actions, such as stopping EC2 instances, when a budget is exceeded.

## Getting Started

To deploy this solution, you will need to have Terraform and `kubectl` installed and configured with access to your AWS account.

1.  **Deploy the Infrastructure**:
    ```sh
    # Navigate to the Terraform directory for the EKS cluster
    cd infra/terraform/eks-or-ecs

    # Initialize and apply the Terraform configuration
    terraform init
    terraform apply
    ```

2.  **Deploy the Platform Tools**:
    ```sh
    # Deploy Kubecost
    kubectl apply -f platform/kubecost/kubecost.yaml

    # Deploy Grafana with the pre-configured dashboard
    kubectl apply -f platform/grafana/grafana.yaml
    ```

3.  **Deploy the Demo Application**:
    ```sh
    # Deploy the sample application with cost allocation labels
    kubectl apply -f platform/demo-app/demo-app.yaml
    ```

4.  **Access the Cloud Cost Hub**:
    - The Grafana dashboard will be available at the Ingress URL specified in `platform/grafana/grafana.yaml` (e.g., `http://grafana.example.com`).
    - The default login is `admin` / `admin`.

## Conclusion

This project provides a powerful, practical blueprint for any organization looking to build a mature FinOps practice. By leveraging a combination of best-in-class open-source tools and native AWS services, it enables you to gain control over your cloud spending, drive a culture of cost accountability, and ultimately maximize the business value of the cloud.
