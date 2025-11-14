// FirebaseUI initialization module
// FirebaseUI requires the compat API
import firebase from 'firebase/compat/app';
import 'firebase/compat/auth';
import * as firebaseui from 'firebaseui';
import 'firebaseui/dist/firebaseui.css';

// Firebase configuration from window
const getFirebaseConfig = () => {
  return {
    apiKey: window.firebaseConfig?.apiKey || '',
    authDomain: window.firebaseConfig?.authDomain || '',
    projectId: window.firebaseConfig?.projectId || '',
    storageBucket: window.firebaseConfig?.storageBucket || '',
    messagingSenderId: window.firebaseConfig?.messagingSenderId || '',
    appId: window.firebaseConfig?.appId || ''
  };
};

// Initialize Firebase app if not already initialized
let app: any = null;
let auth: any = null;

const initializeFirebase = () => {
  const firebaseConfig = getFirebaseConfig();
  
  if (!firebaseConfig.apiKey || !firebaseConfig.projectId) {
    console.warn('⚠️ Firebase not configured. Please set environment variables.');
    return null;
  }

  // Check if Firebase is already initialized
  if (!firebase.apps.length) {
    try {
      app = firebase.initializeApp(firebaseConfig);
      console.log('✅ Firebase initialized successfully');
    } catch (error) {
      console.error('❌ Firebase initialization failed:', error);
      return null;
    }
  } else {
    app = firebase.apps[0];
  }

  auth = firebase.auth();
  return { app, auth };
};

// Initialize FirebaseUI
export const initializeFirebaseUI = (containerId: string, options?: any) => {
  const firebaseInstance = initializeFirebase();
  
  if (!firebaseInstance) {
    console.error('Cannot initialize FirebaseUI: Firebase not configured');
    return null;
  }

  const { auth } = firebaseInstance;

  // Default FirebaseUI configuration
  const defaultUiConfig: firebaseui.auth.Config = {
    signInFlow: 'popup', // Use popup instead of redirect for better UX
    signInSuccessUrl: '/', // Redirect after successful sign-in
    signInOptions: [
      firebase.auth.GoogleAuthProvider.PROVIDER_ID,
      firebase.auth.EmailAuthProvider.PROVIDER_ID,
    ],
    // Terms of service url
    tosUrl: '/terms',
    // Privacy policy url
    privacyPolicyUrl: '/privacy',
    callbacks: {
      signInSuccessWithAuthResult: function(authResult: any, redirectUrl?: string) {
        // User successfully signed in.
        // Return type determines whether we continue the redirect automatically
        // or whether we leave that to developer to handle.
        
        // Get the ID token and send it to our Rails backend
        authResult.user.getIdToken().then((idToken: string) => {
          // Authenticate with backend
          fetch('/api/auth/login', {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              'Authorization': `Bearer ${idToken}`
            }
          }).then(response => {
            if (response.ok) {
              console.log('✅ Backend authentication successful');
              // Redirect after successful authentication
              window.location.href = redirectUrl || '/';
            } else {
              console.error('❌ Backend authentication failed');
            }
          }).catch(error => {
            console.error('❌ Backend authentication error:', error);
          });
        });

        // Return true to continue with redirect, false to handle redirect manually
        return false; // We'll handle redirect manually after backend auth
      },
      uiShown: function() {
        // The widget is rendered.
        // Hide the loader if it exists
        const loader = document.getElementById('loader');
        if (loader) {
          loader.style.display = 'none';
        }
      },
      signInFailure: function(error: any) {
        // Handle merge conflicts for anonymous users
        if (error.code === 'firebaseui/anonymous-upgrade-merge-conflict') {
          // The credential the user tried to sign in with
          const cred = error.credential;
          // Finish sign-in after data is copied
          return auth.signInWithCredential(cred);
        }
        return Promise.resolve();
      }
    }
  };

  // Merge with custom options
  const uiConfig = { ...defaultUiConfig, ...options };

  // Initialize FirebaseUI
  const ui = new firebaseui.auth.AuthUI(auth);
  
  // Start FirebaseUI
  ui.start(`#${containerId}`, uiConfig);

  return ui;
};

// Export Firebase instance getters
export const getFirebaseApp = () => {
  if (!app) {
    initializeFirebase();
  }
  return app;
};

export const getFirebaseAuth = () => {
  if (!auth) {
    initializeFirebase();
  }
  return auth;
};

