@echo off
echo ========================================
echo Firebase Cloud Functions Deployment
echo ========================================
echo.

REM Check if Firebase CLI is installed
firebase --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Firebase CLI not found!
    echo.
    echo Please install Firebase CLI:
    echo npm install -g firebase-tools
    echo.
    pause
    exit /b 1
)

echo [1/5] Checking Firebase login...
firebase login:list >nul 2>&1
if %errorlevel% neq 0 (
    echo You need to login to Firebase first.
    echo.
    firebase login
    if %errorlevel% neq 0 (
        echo ERROR: Firebase login failed!
        pause
        exit /b 1
    )
)
echo ✓ Firebase login OK
echo.

echo [2/5] Installing dependencies...
cd functions
if not exist "node_modules" (
    echo Installing npm packages...
    call npm install
    if %errorlevel% neq 0 (
        echo ERROR: npm install failed!
        cd ..
        pause
        exit /b 1
    )
) else (
    echo Dependencies already installed.
)
echo ✓ Dependencies OK
echo.

cd ..

echo [3/5] Deploying Cloud Functions...
echo This may take 2-5 minutes...
echo.
firebase deploy --only functions
if %errorlevel% neq 0 (
    echo.
    echo ERROR: Deployment failed!
    echo.
    echo Common issues:
    echo - Blaze plan not enabled (upgrade required)
    echo - Wrong Firebase project selected
    echo - Network connection issues
    echo.
    pause
    exit /b 1
)
echo.
echo ✓ Deployment successful!
echo.

echo [4/5] Verifying deployment...
firebase functions:list 2>nul
echo.

echo [5/5] Testing Firebase connection...
firebase projects:list 2>nul
echo.

echo ========================================
echo ✓ DEPLOYMENT COMPLETE!
echo ========================================
echo.
echo Next steps:
echo 1. Open Firebase Console
echo 2. Go to Functions tab
echo 3. Verify 'sendNotificationOnNewSMS' is deployed
echo 4. Test by closing your app and sending an SMS
echo.
echo Cost: Free tier includes 2M invocations/month
echo Normal usage will be within free limits!
echo.
pause
