# Quick Firebase Setup Guide

## Current Status
Firebase authentication is **not configured**. You're currently using **Devise** for authentication.

## Quick Setup Options

### Option 1: Use Devise (Already Working) ✅
Devise is already set up and working. You can:
- Sign up at: http://localhost:3000/users/sign_up
- Sign in at: http://localhost:3000/users/sign_in

### Option 2: Set Up Firebase Authentication

#### Step 1: Create Firebase Project
1. Go to https://console.firebase.google.com/
2. Click "Add project" or "Create a project"
3. Name it (e.g., "pricebreak-app")
4. Follow the setup wizard

#### Step 2: Enable Authentication
1. In Firebase Console → Authentication
2. Click "Get started"
3. Go to "Sign-in method" tab
4. Enable "Email/Password" and/or "Google"

#### Step 3: Get Web App Config
1. Firebase Console → Project Settings (gear icon)
2. Scroll to "Your apps" → Click web icon (</>)
3. Register app name
4. Copy the config object

#### Step 4: Set Environment Variables
Create a `.env` file in the project root (or add to your shell):

```bash
export FIREBASE_API_KEY="your-api-key-here"
export FIREBASE_AUTH_DOMAIN="your-project.firebaseapp.com"
export FIREBASE_PROJECT_ID="your-project-id"
export FIREBASE_STORAGE_BUCKET="your-project.appspot.com"
export FIREBASE_MESSAGING_SENDER_ID="123456789"
export FIREBASE_APP_ID="your-app-id"
```

#### Step 5: Restart Server
```bash
# Stop the server
kill $(lsof -ti:3000)

# Start again (will load .env variables)
bin/rails server
```

## For Now: Use Devise

Since Firebase isn't configured, **use Devise authentication**:

1. **Sign Up**: http://localhost:3000/users/sign_up
2. **Sign In**: http://localhost:3000/users/sign_in
3. After signing in, you'll have access to all protected routes

## Testing After Setup

Once Firebase is configured, test at:
- Home page: http://localhost:3000
- Should see "Sign In with Google" button working

