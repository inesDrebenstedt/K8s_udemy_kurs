@echo off

setlocal enabledelayedexpansion

:: 1. Define user, context, and namespace names
set USER_SA_NAME=my-new-user-sa
set CONTEXT_NAME=my-new-context
set CLUSTER_NAME=docker-desktop
set NAMESPACE_NAME=my-new-namespace

echo --- Creating Namespace: %NAMESPACE_NAME% ---
:: 2. Create the new namespace (using apply for idempotency)
kubectl create namespace %NAMESPACE_NAME% --dry-run=client -o yaml | kubectl apply -f -
IF %ERRORLEVEL% NEQ 0 (
    echo Error: Failed to create/ensure namespace %NAMESPACE_NAME%.
    exit /b 1
)

echo --- Creating Service Account: %USER_SA_NAME% ---
:: 3. Create a Service Account for the user in the new namespace (using apply for idempotency)
kubectl create serviceaccount %USER_SA_NAME% --namespace=%NAMESPACE_NAME% --dry-run=client -o yaml | kubectl apply -f -
IF %ERRORLEVEL% NEQ 0 (
    echo Error: Failed to create/ensure service account %USER_SA_NAME% in %NAMESPACE_NAME%.
    exit /b 1
)

echo --- Granting permissions to Service Account: %USER_SA_NAME% ---
:: 4. Grant permissions to the new Service Account using RBAC
kubectl apply -f test2.yaml
IF %ERRORLEVEL% NEQ 0 (
    echo Error: Failed to apply RBAC permissions from test2.yaml.
    exit /b 1
)

echo --- Retrieving Service Account token ---
:: 5. Get the authentication token from the Service Account
set "TOKEN="
set "SA_SECRET_NAME="
set "ENCODED_TOKEN="

:: Attempt to get the secret token for older Kubernetes versions (pre 1.24)
:: Using double quotes for jsonpath for robustness in batch, and 2^>NUL to suppress stderr.
for /f "delims=" %%i in ('kubectl get serviceaccount %USER_SA_NAME% --namespace=%NAMESPACE_NAME% -o jsonpath="{.secrets[0].name}" 2^>NUL') do (
    set "SA_SECRET_NAME=%%i"
)

if not "%SA_SECRET_NAME%"=="" (
    echo Attempting to retrieve token from secret: %SA_SECRET_NAME%
    :: Extract the token from the secret (which will be base64 encoded)
    for /f "delims=" %%i in ('kubectl get secret %SA_SECRET_NAME% --namespace=%NAMESPACE_NAME% -o jsonpath="{.data.token}" 2^>NUL') do (
        set "ENCODED_TOKEN=%%i"
    )

    if not "%ENCODED_TOKEN%"=="" (
        :: Decode the base64 token using certutil
        echo %ENCODED_TOKEN% | certutil -decode - > temp_token.txt
        for /f "usebackq delims=" %%i in ("temp_token.txt") do set "TOKEN=%%i"
        del temp_token.txt
        if "%TOKEN%"=="" (
            echo Warning: Decoding token from secret failed or resulted in an empty token.
        )
    ) else (
        echo Warning: No encoded token found in secret %SA_SECRET_NAME%.
    )
)

:: Fallback for newer Kubernetes versions (1.24+) or if no secret token was found/decoded
if "%TOKEN%"=="" (
    echo No traditional secret token found or decoding failed. Attempting to create a temporary token using "kubectl create token".
    :: This command directly outputs the raw token, no base64 decoding needed.
    for /f "delims=" %%i in ('kubectl create token %USER_SA_NAME% --namespace=%NAMESPACE_NAME% 2^>NUL') do set "TOKEN=%%i"
)

if "%TOKEN%"=="" (
    echo Error: Could not retrieve or create a token for service account %USER_SA_NAME% in namespace %NAMESPACE_NAME%.
    exit /b 1
) else (
    echo Token successfully retrieved/created.
)

echo --- Configuring Kubernetes credentials in kubeconfig ---
:: 6. Configure Kubernetes credentials in kubeconfig
kubectl config set-credentials %USER_SA_NAME% --token="%TOKEN%"
IF %ERRORLEVEL% NEQ 0 (
    echo Error: Failed to set kubeconfig credentials for user %USER_SA_NAME%.
    exit /b 1
)

echo --- Creating the new context ---
:: 7. Create the new context
kubectl config set-context %CONTEXT_NAME% ^
  --cluster=%CLUSTER_NAME% ^
  --user=%USER_SA_NAME% ^
  --namespace=%NAMESPACE_NAME%
IF %ERRORLEVEL% NEQ 0 (
    echo Error: Failed to create new kubeconfig context %CONTEXT_NAME%.
    exit /b 1
)

echo --- Verification ---
:: 8. Verify the new contexts
kubectl config get-contexts

echo --- Switching to new context: %CONTEXT_NAME% ---
:: 9. Switch to the new context (for testing)
kubectl config use-context %CONTEXT_NAME%
IF %ERRORLEVEL% NEQ 0 (
    echo Error: Failed to switch to new context %CONTEXT_NAME%.
    exit /b 1
)

echo --- Testing permissions with new context ---
:: 10. Test permissions (should show all resources due to cluster-admin binding)
kubectl get all --all-namespaces
IF %ERRORLEVEL% NEQ 0 (
    echo Warning: Permissions test might have failed. Check output above.
)

echo --- Done! Switching back to main context ---
:: Optional: Switch back to your default context if you don't want to stay in the new one
:: Assuming your original context is named after your cluster (e.g., docker-desktop)
kubectl config use-context "%CLUSTER_NAME%"
IF %ERRORLEVEL% NEQ 0 (
    echo Warning: Could not switch back to original context %CLUSTER_NAME%.
)

endlocal