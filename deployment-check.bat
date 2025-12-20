@echo off
REM AKS Deployment Quick Check
REM Simple batch file for deployment verification

echo.
echo ========================================
echo AKS Deployment Status Check
echo ========================================
echo.

cd /d D:\IGM\aks

REM Check Terraform
echo [1] Terraform Validation...
call terraform validate >nul 2>&1
if %errorlevel% equ 0 (
    echo    PASS: Terraform configuration is valid
) else (
    echo    FAIL: Terraform configuration has errors
)

REM Check state
echo.
echo [2] Terraform State Status...
if exist terraform.tfstate (
    echo    OK: terraform.tfstate exists
    
    REM Count resources
    for /f %%a in ('terraform state list ^| find /c /v ""') do (
        echo    Resources: %%a deployed
    )
) else (
    echo    FAIL: terraform.tfstate not found
)

REM Check tfvars
echo.
echo [3] Configuration Files...
if exist terraform.tfvars (
    echo    OK: terraform.tfvars exists
) else (
    echo    WARN: terraform.tfvars not found
    if exist terraform.tfvars.example (
        echo          Run: copy terraform.tfvars.example terraform.tfvars
    )
)

REM Check K8s manifests
echo.
echo [4] Kubernetes Manifests...
if exist k8s\n8n\deployment.yaml (
    echo    OK: n8n deployment.yaml exists
) else (
    echo    FAIL: deployment.yaml not found
)

if exist k8s\n8n\secret.yaml (
    echo    OK: n8n secret.yaml exists
) else (
    echo    FAIL: secret.yaml not found
)

REM Check ArgoCD
echo.
echo [5] ArgoCD Configuration...
if exist argocd\n8n-application.yaml (
    echo    OK: ArgoCD application manifest exists
    
    findstr "YOUR-ORG" argocd\n8n-application.yaml >nul
    if %errorlevel% equ 0 (
        echo    WARN: GitHub repository URL needs to be updated
    ) else (
        echo    OK: GitHub repository URL is configured
    )
) else (
    echo    FAIL: ArgoCD application manifest not found
)

echo.
echo ========================================
echo Quick Deploy Instructions:
echo ========================================
echo.
echo Step 1: Configure terraform.tfvars
echo   - Set mysql_admin_password
echo.
echo Step 2: Deploy Infrastructure
echo   terraform plan -out=tfplan
echo   terraform apply tfplan
echo.
echo Step 3: Deploy Applications
echo   az aks get-credentials --resource-group rg-useful-cougar --name cluster-crucial-terrapin
echo   kubectl apply -f k8s/n8n/
echo.
echo ========================================
echo.

pause
