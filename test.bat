@echo off
echo Testing FinOps Container Optimization

echo 1. Testing Docker builds...
docker build -t inference-api:test services/inference-api/ || exit /b 1
docker build -t batch-worker:test services/batch-worker/ || exit /b 1

echo 2. Testing service health...
docker run -d -p 8000:8000 --name test-api inference-api:test
timeout /t 5 /nobreak >nul
curl -f http://localhost:8000/health || exit /b 1
docker stop test-api
docker rm test-api

echo 3. Validating Terraform...
cd infra\terraform\vpc && terraform init && terraform validate || exit /b 1
cd ..\eks-or-ecs && terraform init && terraform validate || exit /b 1
cd ..\..\..

echo All tests passed!