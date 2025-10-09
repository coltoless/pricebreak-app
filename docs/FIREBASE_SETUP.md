# Firebase Authentication Setup Guide for PriceBreak

This guide will help you set up Firebase Authentication for your PriceBreak Rails application.

## Prerequisites

- A Google account
- Node.js and npm (for Firebase CLI)
- Rails application running

## Step 1: Create a Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project" or "Add project"
3. Enter a project name (e.g., "pricebreak-app")
4. Choose whether to enable Google Analytics (optional)
5. Click "Create project"

## Step 2: Enable Authentication

1. In your Firebase project, click "Authentication" in the left sidebar
2. Click "Get started"
3. Click on the "Sign-in method" tab
4. Enable "Google" as a sign-in provider:
   - Click on "Google"
   - Toggle "Enable"
   - Add your support email
   - Click "Save"
5. Optionally enable "Email/Password" authentication

## Step 3: Create a Web App

1. In your Firebase project, click the gear icon next to "Project Overview"
2. Select "Project settings"
3. Scroll down to "Your apps" section
4. Click the web icon (</>)
5. Enter an app nickname (e.g., "pricebreak-web")
6. Click "Register app"
7. Copy the Firebase configuration object

## Step 4: Get Service Account Credentials

1. In Project settings, go to "Service accounts" tab
2. Click "Generate new private key"
3. Download the JSON file
4. **Keep this file secure and never commit it to version control**

## Step 5: Configure Rails Credentials

1. Run the following command to edit your Rails credentials:
   ```bash
   rails credentials:edit
   ```

2. Add your Firebase configuration under the `firebase:` key:
   ```yaml
   firebase:
     project_id: "your-project-id"
     private_key_id: "your-private-key-id"
     private_key: |
       -----BEGIN PRIVATE KEY-----
       your-private-key-content
       -----END PRIVATE KEY-----
     client_email: "your-service-account-email"
     client_id: "your-client-id"
     auth_uri: "https://accounts.google.com/o/oauth2/auth"
     token_uri: "https://oauth2.googleapis.com/token"
     auth_provider_x509_cert_url: "https://www.googleapis.com/oauth2/v1/certs"
     client_x509_cert_url: "your-cert-url"
   ```

3. Save and exit the editor

## Step 6: Set Environment Variables

Add these environment variables to your `.env` file or set them in your shell:

```bash
export FIREBASE_API_KEY="your-api-key"
export FIREBASE_AUTH_DOMAIN="your-project.firebaseapp.com"
export FIREBASE_PROJECT_ID="your-project-id"
```

## Step 7: Test the Setup

1. Start your Rails server:
   ```bash
   bin/dev
   ```

2. Visit your application in the browser
3. You should see a "Sign In with Google" button in the header
4. Click it to test the authentication flow

## Step 8: Verify Backend Integration

1. After signing in, check your Rails logs for Firebase authentication messages
2. Verify that a user record is created in your database
3. Check the `/api/auth/me` endpoint to see user information

## Troubleshooting

### Common Issues

1. **"Firebase SDK not loaded" error**
   - Check that Firebase scripts are included in your layout
   - Verify the script URLs are accessible

2. **"Firebase credentials not found" error**
   - Ensure you've added Firebase credentials to `rails credentials:edit`
   - Check that the credentials file is properly encrypted

3. **Authentication fails on backend**
   - Verify your Firebase service account credentials
   - Check that the Firebase Admin SDK gem is installed
   - Ensure your Firebase project has Authentication enabled

4. **CORS errors**
   - Add your domain to Firebase Authentication authorized domains
   - Check that your API endpoints are properly configured

### Debug Mode

To enable debug logging, add this to your `config/environments/development.rb`:

```ruby
config.log_level = :debug
```

## Security Considerations

1. **Never commit Firebase credentials to version control**
2. **Use environment variables for frontend Firebase config in production**
3. **Implement proper CORS policies**
4. **Add rate limiting to authentication endpoints**
5. **Validate Firebase tokens on every request**

## Next Steps

After successful setup, you can:

1. **Customize the UI** - Modify the authentication buttons and user info display
2. **Add more providers** - Enable Facebook, Twitter, or other authentication methods
3. **Implement user roles** - Add role-based access control
4. **Add profile management** - Allow users to update their information
5. **Integrate with existing features** - Connect authentication to flight alerts and preferences

## Support

If you encounter issues:

1. Check the [Firebase Documentation](https://firebase.google.com/docs)
2. Review the Rails logs for error messages
3. Verify your Firebase project configuration
4. Check that all gems are properly installed

## Example Firebase Configuration

Here's what your Firebase config should look like in the frontend:

```javascript
const firebaseConfig = {
  apiKey: "your-api-key",
  authDomain: "your-project.firebaseapp.com",
  projectId: "your-project-id",
  storageBucket: "your-project.appspot.com",
  messagingSenderId: "123456789",
  appId: "your-app-id"
};
```

Replace the placeholder values with your actual Firebase project configuration.

