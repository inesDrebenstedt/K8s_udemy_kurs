@echo off
setlocal enabledelayedexpansion

:: 1. Define user, context, and namespace names
set USER_SA_NAME=my-new-user-sa
set CONTEXT_NAME=my-new-context
set CLUSTER_NAME=docker-desktop
set NAMESPACE_NAME=my-new-namespace

echo --- Creating Namespace: %NAMESPACE_NAME% ---
:: 2. Create the new namespace
kubectl create namespace %NAMESPACE_NAME%

echo --- Creating Service Account: %USER_SA_NAME% ---
:: 3. Create a Service Account for the user in the new namespace
kubectl create serviceaccount %USER_SA_NAME% --namespace=%NAMESPACE_NAME%

echo --- Granting permissions to Service Account: %USER_SA_NAME% ---
:: 4. Apply ClusterRoleBinding from YAML file (test2.yaml)
kubectl apply -f test2.yaml

echo --- Retrieving Service Account token ---
:: 5. Get the authentication token from the Service Account
:: This step retrieves the token using `kubectl create token` (recommended for newer Kubernetes versions)
for /f "delims=" %%i in ('kubectl create token %USER_SA_NAME% --namespace=%NAMESPACE_NAME%') do set TOKEN=%%i

if "%TOKEN%"=="" (
    echo Error: Could not retrieve or create a token for service account %USER_SA_NAME%.
    exit /b 1
)

echo --- Configuring Kubernetes credentials in kubeconfig ---
:: 6. Configure Kubernetes credentials in kubeconfig
kubectl config set-credentials %USER_SA_NAME% --token="%TOKEN%"

echo --- Creating the new context ---
:: 7. Create the new context
kubectl config set-context %CONTEXT_NAME% ^
  --cluster=%CLUSTER_NAME% ^
  --user=%USER_SA_NAME% ^
  --namespace=%NAMESPACE_NAME%

echo --- Verification ---
:: 8. Verify the new context
kubectl config get-contexts

echo --- Switching to new context: %CONTEXT_NAME% ---
:: 9. Switch to the new context (for testing)
kubectl config use-context %CONTEXT_NAME%

echo --- Testing permissions with new context ---
:: 10. Test permissions
kubectl get all

echo --- Done! Switched back to main context ---
:: Optional: Switch back to your default context if you don't want to stay in the new one
:: kubectl config use-context docker-desktop

endlocal
