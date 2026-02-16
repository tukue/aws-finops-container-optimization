@echo off
setlocal enabledelayedexpansion

REM AI & Kubernetes Cost Optimization Simulation Test Script (Windows)
REM This script demonstrates the complete optimization workflow

echo 🚀 Starting AI ^& Kubernetes Cost Optimization Simulation
echo ========================================================

REM Configuration
if "%NAMESPACE%"=="" set NAMESPACE=default
if "%DOCKER_REGISTRY%"=="" set DOCKER_REGISTRY=localhost:5000

REM Function to print steps
:print_step
echo.
echo 📋 Step: %~1
goto :eof

:print_success
echo ✅ %~1
goto :eof

:print_warning
echo ⚠️  %~1
goto :eof

:print_error
echo ❌ %~1
goto :eof

REM Function to check if kubectl is available
:check_kubectl
kubectl cluster-info >nul 2>&1
if errorlevel 1 (
    call :print_error "Cannot connect to Kubernetes cluster"
    exit /b 1
)
call :print_success "Kubernetes cluster connection verified"
goto :eof

REM Function to wait for deployment
:wait_for_deployment
echo Waiting for deployment %~1 to be ready...
kubectl wait --for=condition=available --timeout=300s deployment/%~1 -n %~2
goto :eof

REM Function to build and push Docker images
:build_and_push_images
call :print_step "Building and pushing Docker images"

echo Building ai-gateway-mock...
docker build -t %DOCKER_REGISTRY%/ai-gateway-mock:latest services/ai-gateway-mock/
docker push %DOCKER_REGISTRY%/ai-gateway-mock:latest

echo Building ai-load-generator...
docker build -t %DOCKER_REGISTRY%/ai-load-generator:latest services/ai-load-generator/
docker push %DOCKER_REGISTRY%/ai-load-generator:latest

call :print_success "Docker images built and pushed"
goto :eof

REM Function to deploy Phase 1
:deploy_phase1
call :print_step "Phase 1: Deploying Unoptimized State"

kubectl apply -f platform/optimization-simulation/overprovisioned-app.yaml

REM Update image in AI Gateway manifest and apply
powershell -Command "(Get-Content platform/ai-gateway/ai-gateway.yaml) -replace 'ai-gateway-mock:latest', '%DOCKER_REGISTRY%/ai-gateway-mock:latest' | kubectl apply -f -"

call :wait_for_deployment "overprovisioned-app" %NAMESPACE%
call :wait_for_deployment "ai-gateway-mock" %NAMESPACE%
call :wait_for_deployment "redis" %NAMESPACE%

call :print_success "Phase 1 deployments ready"
goto :eof

REM Function to run unoptimized load test
:run_unoptimized_load
call :print_step "Running Unoptimized Load Test (5 minutes)"

REM Update load generator image and apply
powershell -Command "(Get-Content platform/ai-load-generator/load-generator.yaml) -replace 'ai-load-generator:latest', '%DOCKER_REGISTRY%/ai-load-generator:latest' | kubectl apply -f -"

echo Running unoptimized load for 5 minutes...
kubectl wait --for=condition=complete --timeout=400s job/ai-load-generator-unoptimized

echo Unoptimized load test results:
kubectl logs job/ai-load-generator-unoptimized

call :print_success "Unoptimized load test completed"
goto :eof

REM Function to collect Phase 1 metrics
:collect_phase1_metrics
call :print_step "Collecting Phase 1 Metrics"

echo Getting AI Gateway metrics...
start /b kubectl port-forward service/ai-gateway-service 8080:80
timeout /t 5 /nobreak >nul

curl -s http://localhost:8080/metrics | findstr /r "ai_cost_total ai_tokens_total ai_cache" 2>nul
curl -s http://localhost:8080/stats 2>nul

taskkill /f /im kubectl.exe >nul 2>&1

echo Getting Kubernetes resource usage...
kubectl top pods --no-headers 2>nul | head -10

call :print_success "Phase 1 metrics collected"
goto :eof

REM Function to deploy Phase 2
:deploy_phase2
call :print_step "Phase 2: Applying Optimizations"

kubectl apply -f platform/optimization-simulation/rightsized-app.yaml
call :wait_for_deployment "rightsized-app" %NAMESPACE%

call :print_success "Phase 2 optimizations applied"
goto :eof

REM Function to run optimized load test
:run_optimized_load
call :print_step "Running Optimized Load Test (5 minutes)"

kubectl delete job ai-load-generator-unoptimized --ignore-not-found=true
timeout /t 10 /nobreak >nul

kubectl create job ai-load-generator-optimized-test --from=job/ai-load-generator-optimized

echo Running optimized load for 5 minutes...
kubectl wait --for=condition=complete --timeout=400s job/ai-load-generator-optimized-test

echo Optimized load test results:
kubectl logs job/ai-load-generator-optimized-test

call :print_success "Optimized load test completed"
goto :eof

REM Function to generate report
:generate_report
call :print_step "Generating Optimization Report"

echo.
echo 🎯 AI ^& Kubernetes Cost Optimization Results
echo ============================================
echo.
echo Phase 1 (Unoptimized):
echo - Over-provisioned Kubernetes pods
echo - AI requests using expensive models (GPT-4)
echo - No caching enabled
echo - High token consumption
echo.
echo Phase 2 (Optimized):
echo - Right-sized Kubernetes pods (60%% resource reduction)
echo - Mixed AI model routing (GPT-4: 30%%, GPT-3.5: 50%%, Claude Haiku: 20%%)
echo - Caching enabled (70%% cache hit rate expected)
echo - Significant cost reduction
echo.
echo Expected Savings:
echo - Kubernetes compute: ~40%% reduction
echo - AI token costs: ~60%% reduction
echo - Total infrastructure: ~50%% cost savings
echo.
echo Next Steps:
echo 1. Monitor Grafana dashboard for real-time metrics
echo 2. Enable Karpenter for spot instance usage
echo 3. Implement automated scaling policies
echo 4. Set up cost alerts and budgets
echo.

call :print_success "Optimization simulation completed successfully!"
goto :eof

REM Function to setup monitoring
:setup_monitoring
call :print_step "Setting up Monitoring"

kubectl apply -f platform/grafana/grafana.yaml
call :wait_for_deployment "grafana" %NAMESPACE%

echo Grafana dashboard available at: http://localhost:3000
echo Default credentials: admin/admin

call :print_success "Monitoring setup completed"
goto :eof

REM Function to cleanup
:cleanup
call :print_step "Cleaning up resources"

kubectl delete job ai-load-generator-unoptimized --ignore-not-found=true
kubectl delete job ai-load-generator-optimized-test --ignore-not-found=true
kubectl delete -f platform/ai-gateway/ai-gateway.yaml --ignore-not-found=true
kubectl delete -f platform/optimization-simulation/overprovisioned-app.yaml --ignore-not-found=true
kubectl delete -f platform/optimization-simulation/rightsized-app.yaml --ignore-not-found=true

call :print_success "Cleanup completed"
goto :eof

REM Main execution
:main
echo Starting AI ^& Kubernetes Cost Optimization Simulation
echo Namespace: %NAMESPACE%
echo Docker Registry: %DOCKER_REGISTRY%
echo.

call :check_kubectl

if "%~1"=="build" (
    call :build_and_push_images
) else if "%~1"=="phase1" (
    call :deploy_phase1
    call :run_unoptimized_load
    call :collect_phase1_metrics
) else if "%~1"=="phase2" (
    call :deploy_phase2
    call :run_optimized_load
) else if "%~1"=="monitoring" (
    call :setup_monitoring
) else if "%~1"=="cleanup" (
    call :cleanup
) else if "%~1"=="all" (
    call :build_and_push_images
    call :deploy_phase1
    call :run_unoptimized_load
    call :collect_phase1_metrics
    call :deploy_phase2
    call :run_optimized_load
    call :generate_report
    call :setup_monitoring
) else (
    echo Usage: %0 [build^|phase1^|phase2^|monitoring^|cleanup^|all]
    echo.
    echo Commands:
    echo   build      - Build and push Docker images
    echo   phase1     - Deploy and test unoptimized state
    echo   phase2     - Deploy and test optimized state
    echo   monitoring - Setup Grafana monitoring
    echo   cleanup    - Remove all deployed resources
    echo   all        - Run complete simulation (default)
    exit /b 1
)

goto :eof

REM Call main function
call :main %*