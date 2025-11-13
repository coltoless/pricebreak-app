# FirebaseUI Authentication Setup

This document describes the FirebaseUI authentication implementation for PriceBreak.

## Overview

FirebaseUI provides a pre-built, customizable authentication UI that supports multiple sign-in providers. It handles the entire authentication flow, including UI rendering, error handling, and token management.

## Implementation Details

### Files Created/Modified

1. **`app/javascript/lib/firebaseui.ts`**
   - FirebaseUI initialization module
   - Uses Firebase compat API (required by FirebaseUI)
   - Configures multiple sign-in providers
   - Handles authentication callbacks

2. **`app/views/auth/sign_in.html.erb`**
   - Sign-in page with FirebaseUI container
   - Styled to match PriceBreak design system
   - Includes loader and error handling

3. **`app/controllers/auth_controller.rb`**
   - Controller for the sign-in page

4. **`config/routes.rb`**
   - Added route: `get 'sign-in', to: 'auth#sign_in'`

5. **`app/javascript/application.js`**
   - Exports `initializeFirebaseUI` function for use in views

### Sign-In Providers Configured

The following providers are enabled in FirebaseUI:

- **Google** (`google.com`)
- **Facebook** (`facebook.com`)
- **Twitter** (`twitter.com`)
- **GitHub** (`github.com`)
- **Email/Password** (`password`)
- **Phone** (`phone`)

### Configuration

FirebaseUI is configured with:

- **Sign-in flow**: Popup (better UX than redirect)
- **Success redirect**: `/` (home page)
- **Terms of service**: `/terms` (update as needed)
- **Privacy policy**: `/privacy` (update as needed)

### Authentication Flow

1. User visits `/sign-in` page
2. FirebaseUI widget renders with available sign-in options
3. User selects a provider and completes authentication
4. FirebaseUI callback receives authentication result
5. ID token is sent to Rails backend (`/api/auth/login`)
6. Backend verifies token and creates/updates user
7. User is redirected to home page

### Backend Integration

The FirebaseUI implementation integrates with the existing Rails backend:

- **Endpoint**: `POST /api/auth/login`
- **Headers**: `Authorization: Bearer <firebase-id-token>`
- **Response**: User data (id, email, name, firebase_uid)

The backend controller (`Api::AuthController`) handles:
- Token verification using Firebase Admin SDK
- User creation/update in the database
- Session management

## Usage

### Accessing the Sign-In Page

Users can access the sign-in page at:
```
http://localhost:3000/sign-in
```

Or use the route helper:
```erb
<%= link_to "Sign In", sign_in_path %>
```

### Customizing Sign-In Options

To customize which providers are shown, edit `app/javascript/lib/firebaseui.ts`:

```typescript
signInOptions: [
  firebase.auth.GoogleAuthProvider.PROVIDER_ID,
  firebase.auth.EmailAuthProvider.PROVIDER_ID,
  // Add or remove providers as needed
],
```

### Customizing UI Configuration

To customize the FirebaseUI configuration, modify the `defaultUiConfig` object in `firebaseui.ts`:

```typescript
const defaultUiConfig: firebaseui.auth.Config = {
  signInFlow: 'popup', // or 'redirect'
  signInSuccessUrl: '/dashboard', // Custom redirect URL
  // ... other options
};
```

## Environment Variables Required

Ensure these environment variables are set:

```bash
FIREBASE_API_KEY=your-api-key
FIREBASE_AUTH_DOMAIN=your-project.firebaseapp.com
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_STORAGE_BUCKET=your-project.appspot.com
FIREBASE_MESSAGING_SENDER_ID=123456789
FIREBASE_APP_ID=your-app-id
```

## Firebase Console Setup

1. **Enable Authentication Providers**
   - Go to Firebase Console → Authentication → Sign-in method
   - Enable the providers you want to use:
     - Google
     - Facebook (requires app ID and secret)
     - Twitter (requires API key and secret)
     - GitHub (requires client ID and secret)
     - Email/Password
     - Phone

2. **Authorized Domains**
   - Go to Authentication → Settings → Authorized domains
   - Add your domain (e.g., `localhost` for development)

## Styling

FirebaseUI CSS is automatically imported. To customize styles:

1. Override FirebaseUI classes in your CSS
2. Use CSS variables if available
3. Fork FirebaseUI and customize the source (advanced)

## Troubleshooting

### FirebaseUI Not Rendering

- Check browser console for errors
- Verify Firebase configuration is set correctly
- Ensure FirebaseUI CSS is loaded
- Check that the container element exists

### Authentication Fails

- Verify provider is enabled in Firebase Console
- Check authorized domains in Firebase Console
- Verify backend endpoint is accessible
- Check browser console and Rails logs for errors

### Backend Authentication Fails

- Verify Firebase Admin SDK is configured
- Check Rails credentials for Firebase service account
- Verify token is being sent correctly
- Check Rails logs for detailed error messages

## References

- [FirebaseUI Documentation](https://firebase.google.com/docs/auth/web/firebaseui)
- [Firebase Authentication](https://firebase.google.com/docs/auth)
- [FirebaseUI GitHub Repository](https://github.com/firebase/firebaseui-web)

