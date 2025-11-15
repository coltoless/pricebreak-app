import { Controller } from "@hotwired/stimulus"
import { initializeApp, getApps } from 'firebase/app'
import { getAuth, onAuthStateChanged, signInWithPopup, GoogleAuthProvider, createUserWithEmailAndPassword, signInWithEmailAndPassword, signOut } from 'firebase/auth'

// Firebase Authentication Controller
export default class extends Controller {
  static targets = ["signInButton", "signOutButton", "userInfo", "authForm", "emailInput", "passwordInput", "nameInput", "errorMessage"]
  static values = { 
    apiKey: String,
    authDomain: String,
    projectId: String,
    storageBucket: String,
    messagingSenderId: String,
    appId: String
  }

  connect() {
    // Prevent multiple initializations
    if (this.initialized) {
      console.log('Firebase auth controller already initialized, skipping...')
      return
    }
    this.initialized = true
    this.authListenerUnsubscribe = null
    this.authenticating = false
    this.pageLoadComplete = false
    
    // Mark page load as complete after a short delay to prevent redirects during initial load
    setTimeout(() => {
      this.pageLoadComplete = true
      console.log('Page load complete, redirects now allowed')
    }, 2000)
    
    this.initializeFirebase()
    this.checkAuthState()
  }

  disconnect() {
    // Clean up auth listener when controller disconnects
    if (this.authListenerUnsubscribe) {
      this.authListenerUnsubscribe()
      this.authListenerUnsubscribe = null
    }
    this.initialized = false
  }

  initializeFirebase() {
    // Firebase configuration from data attributes or window.firebaseConfig
    const firebaseConfig = {
      apiKey: this.apiKeyValue || window.firebaseConfig?.apiKey || '',
      authDomain: this.authDomainValue || window.firebaseConfig?.authDomain || '',
      projectId: this.projectIdValue || window.firebaseConfig?.projectId || '',
      storageBucket: this.storageBucketValue || window.firebaseConfig?.storageBucket || '',
      messagingSenderId: this.messagingSenderIdValue || window.firebaseConfig?.messagingSenderId || '',
      appId: this.appIdValue || window.firebaseConfig?.appId || ''
    }

    if (!firebaseConfig.apiKey || !firebaseConfig.projectId) {
      console.warn('⚠️ Firebase not configured. Please set environment variables.')
      return
    }

    try {
      // Check if Firebase is already initialized (from firebase.ts)
      const existingApps = getApps()
      if (existingApps.length > 0) {
        // Use the existing Firebase app
        this.app = existingApps[0]
        this.auth = getAuth(this.app)
        console.log('✅ Using existing Firebase app instance')
      } else {
        // Initialize Firebase if not already initialized
        this.app = initializeApp(firebaseConfig)
        this.auth = getAuth(this.app)
        console.log('✅ Firebase initialized in controller')
      }
      this.setupAuthStateListener()
    } catch (error) {
      console.error('Firebase initialization error:', error)
      // Try to get existing app if initialization failed due to duplicate
      const existingApps = getApps()
      if (existingApps.length > 0) {
        this.app = existingApps[0]
        this.auth = getAuth(this.app)
        this.setupAuthStateListener()
        console.log('✅ Recovered using existing Firebase app')
      } else {
        this.showError('Failed to initialize authentication.')
      }
    }
  }

  setupAuthStateListener() {
    // DISABLED on home page to prevent refresh loops
    // Only set up listener on other pages that need real-time auth updates
    const isHomePage = window.location.pathname === '/' || window.location.pathname === ''
    
    if (isHomePage) {
      console.log('⚠️ Auth state listener DISABLED on home page to prevent refresh loops')
      return
    }
    
    if (this.auth && !this.authListenerUnsubscribe) {
      // Only set up listener once
      this.authListenerUnsubscribe = onAuthStateChanged(this.auth, async (user) => {
        // Prevent multiple simultaneous auth state changes
        if (this.processingAuthState) {
          console.log('Auth state change already processing, skipping...')
          return
        }
        
        this.processingAuthState = true
        
        try {
          if (user) {
            await this.onUserSignedIn(user)
          } else {
            // Don't redirect on auth state changes - only update UI
            // This prevents infinite loops when checking auth state on page load
            this.onUserSignedOut(false)
          }
        } finally {
          // Reset flag after a short delay to allow state to stabilize
          setTimeout(() => {
            this.processingAuthState = false
          }, 1000)
        }
      })
    }
  }

  async signInWithGoogle() {
    if (!this.auth) {
      this.showError('Authentication not initialized. Please refresh the page.')
      return
    }

    try {
      const provider = new GoogleAuthProvider()
      const result = await signInWithPopup(this.auth, provider)
      
      if (result.user) {
        // Get the ID token and send it to our Rails backend
        const idToken = await result.user.getIdToken()
        await this.authenticateWithBackend(idToken)
      }
    } catch (error) {
      console.error('Google sign-in error:', error)
      this.showError(this.getErrorMessage(error))
    }
  }

  async signUpWithEmail() {
    if (!this.auth) {
      this.showError('Authentication not initialized. Please refresh the page.')
      return
    }

    const email = this.hasEmailInputTarget ? this.emailInputTarget.value : ''
    const password = this.hasPasswordInputTarget ? this.passwordInputTarget.value : ''
    const name = this.hasNameInputTarget ? this.nameInputTarget.value : ''

    if (!email || !password) {
      this.showError('Please enter both email and password.')
      return
    }

    if (password.length < 6) {
      this.showError('Password must be at least 6 characters.')
      return
    }

    try {
      const userCredential = await createUserWithEmailAndPassword(this.auth, email, password)
      
      // Update display name if provided
      if (name && userCredential.user) {
        await userCredential.user.updateProfile({ displayName: name })
      }

      // Get the ID token and send it to our Rails backend
      const idToken = await userCredential.user.getIdToken()
      await this.authenticateWithBackend(idToken, 'register')
    } catch (error) {
      console.error('Email sign-up error:', error)
      this.showError(this.getErrorMessage(error))
    }
  }

  async signInWithEmail() {
    if (!this.auth) {
      this.showError('Authentication not initialized. Please refresh the page.')
      return
    }

    const email = this.hasEmailInputTarget ? this.emailInputTarget.value : ''
    const password = this.hasPasswordInputTarget ? this.passwordInputTarget.value : ''

    if (!email || !password) {
      this.showError('Please enter both email and password.')
      return
    }

    try {
      const userCredential = await signInWithEmailAndPassword(this.auth, email, password)
      
      // Get the ID token and send it to our Rails backend
      const idToken = await userCredential.user.getIdToken()
      await this.authenticateWithBackend(idToken)
    } catch (error) {
      console.error('Email sign-in error:', error)
      this.showError(this.getErrorMessage(error))
    }
  }

  async signOut() {
    if (!this.auth) return

    try {
      await signOut(this.auth)
      // Pass true to indicate this is an actual sign-out action, so redirect is allowed
      this.onUserSignedOut(true)
      
      // Also notify backend
      try {
        await fetch('/api/auth/logout', {
          method: 'DELETE',
          headers: {
            'Content-Type': 'application/json'
          }
        })
      } catch (e) {
        // Ignore backend logout errors
        console.log('Backend logout notification failed (non-critical)')
      }
    } catch (error) {
      console.error('Sign-out error:', error)
      this.showError('Sign-out failed. Please try again.')
    }
  }

  async authenticateWithBackend(idToken, endpoint = 'login') {
    try {
      const url = endpoint === 'register' ? '/api/auth/register' : '/api/auth/login'
      const response = await fetch(url, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${idToken}`
        }
      })

      if (response.ok) {
        const data = await response.json()
        console.log('Backend authentication successful:', data)
        this.updateUserInfo(data.user)
        
        // Clear form fields if they exist
        if (this.hasEmailInputTarget) this.emailInputTarget.value = ''
        if (this.hasPasswordInputTarget) this.passwordInputTarget.value = ''
        if (this.hasNameInputTarget) this.nameInputTarget.value = ''
      } else {
        const errorData = await response.json().catch(() => ({}))
        console.error('Backend authentication failed:', errorData)
        // Don't show errors on home page to prevent loops
        const isHomePage = window.location.pathname === '/' || window.location.pathname === ''
        if (!isHomePage) {
          this.showError(errorData.error || 'Authentication failed. Please try again.')
        }
      }
    } catch (error) {
      console.error('Backend authentication error:', error)
      // Don't show errors on home page to prevent loops
      const isHomePage = window.location.pathname === '/' || window.location.pathname === ''
      if (!isHomePage) {
        this.showError('Authentication failed. Please try again.')
      }
    }
  }

  async onUserSignedIn(user) {
    // Don't authenticate with backend on home page - just update UI
    // This prevents authentication failures and loops
    const isHomePage = window.location.pathname === '/' || window.location.pathname === ''
    
    if (isHomePage) {
      console.log('Home page: Skipping backend authentication, updating UI only')
      // Just update UI, don't call backend
    } else {
      // Prevent multiple simultaneous authentication calls
      if (this.authenticating) {
        console.log('Already authenticating with backend, skipping...')
        // Still update UI even if we skip backend auth
      } else {
        // Get fresh token and authenticate with backend
        try {
          this.authenticating = true
          const idToken = await user.getIdToken()
          await this.authenticateWithBackend(idToken)
        } catch (error) {
          console.error('Failed to get ID token:', error)
        } finally {
          this.authenticating = false
        }
      }
    }

    // Update UI to show signed-in state
    if (this.hasSignInButtonTarget) {
      this.signInButtonTarget.style.display = 'none'
    }
    
    if (this.hasSignOutButtonTarget) {
      this.signOutButtonTarget.style.display = 'block'
    }

    if (this.hasUserInfoTarget) {
      this.userInfoTarget.style.display = 'block'
      this.userInfoTarget.innerHTML = `
        <div class="user-info">
          <div class="user-info-content">
            <p style="margin: 0; font-weight: 600;">Welcome, ${user.displayName || user.email}!</p>
            <p style="margin: 0.25rem 0 0 0; font-size: 0.8rem; opacity: 0.9;">${user.email}</p>
          </div>
          <a href="/account" class="user-account-link" style="display: inline-flex; align-items: center; gap: 0.5rem; margin-top: 0.75rem; padding: 0.5rem 0.75rem; background: rgba(255, 255, 255, 0.15); border-radius: 0.375rem; color: white; text-decoration: none; font-size: 0.875rem; transition: all 0.2s; border: 1px solid rgba(255, 255, 255, 0.2);">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"></path>
              <circle cx="12" cy="7" r="4"></circle>
            </svg>
            Account & Settings
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <path d="m9 18 6-6-6-6"></path>
            </svg>
          </a>
        </div>
      `
    }

    // Hide auth form if it exists
    if (this.hasAuthFormTarget) {
      this.authFormTarget.style.display = 'none'
    }
  }

  onUserSignedOut(shouldRedirect = false) {
    // Only redirect if explicitly requested AND page load is complete AND not already on home page AND redirects are allowed
    // Don't redirect on auth state checks to prevent infinite loops
    const redirectsAllowed = window.allowRedirects !== false;
    const timeSinceLoad = window.pageLoadTime ? Date.now() - window.pageLoadTime : 9999;
    
    if (shouldRedirect && this.pageLoadComplete && window.location.pathname !== '/' && redirectsAllowed && timeSinceLoad > 3000) {
      console.log('Redirecting to home page after sign out')
      window.location.href = '/'
      return // Exit early if redirecting
    }
    
    // Log if redirect was prevented
    if (shouldRedirect) {
      console.log('Redirect prevented - pageLoadComplete:', this.pageLoadComplete, 
                  'currentPath:', window.location.pathname, 
                  'redirectsAllowed:', redirectsAllowed,
                  'timeSinceLoad:', timeSinceLoad)
    }
    
    // Update UI to show signed-out state
    if (this.hasSignInButtonTarget) {
      this.signInButtonTarget.style.display = 'block'
    }
    
    if (this.hasSignOutButtonTarget) {
      this.signOutButtonTarget.style.display = 'none'
    }

    if (this.hasUserInfoTarget) {
      this.userInfoTarget.style.display = 'none'
      this.userInfoTarget.innerHTML = ''
    }

    // Show auth form if it exists
    if (this.hasAuthFormTarget) {
      this.authFormTarget.style.display = 'block'
    }

    // Clear error message
    if (this.hasErrorMessageTarget) {
      this.errorMessageTarget.style.display = 'none'
      this.errorMessageTarget.textContent = ''
    }
  }

  updateUserInfo(user) {
    if (this.hasUserInfoTarget) {
      this.userInfoTarget.innerHTML = `
        <div class="user-info">
          <p>Welcome, ${user.name || user.email}!</p>
          <p>Email: ${user.email}</p>
        </div>
      `
    }
  }

  checkAuthState() {
    // Skip if already processing auth state to prevent conflicts
    if (this.processingAuthState) {
      console.log('Auth state already processing, skipping checkAuthState...')
      return
    }
    
    if (this.auth) {
      // Check current state for immediate UI update (one-time check, no listener)
      const user = this.auth.currentUser
      if (user) {
        // Only update UI, don't authenticate with backend on home page
        // This prevents refresh loops
        console.log('User is signed in, updating UI only')
        if (this.hasSignInButtonTarget) {
          this.signInButtonTarget.style.display = 'none'
        }
        if (this.hasSignOutButtonTarget) {
          this.signOutButtonTarget.style.display = 'block'
        }
        if (this.hasUserInfoTarget) {
          this.userInfoTarget.style.display = 'block'
          this.userInfoTarget.innerHTML = `
            <div class="user-info">
              <div class="user-info-content">
                <p style="margin: 0; font-weight: 600;">Welcome, ${user.displayName || user.email}!</p>
                <p style="margin: 0.25rem 0 0 0; font-size: 0.8rem; opacity: 0.9;">${user.email}</p>
              </div>
              <a href="/account" class="user-account-link" style="display: inline-flex; align-items: center; gap: 0.5rem; margin-top: 0.75rem; padding: 0.5rem 0.75rem; background: rgba(255, 255, 255, 0.15); border-radius: 0.375rem; color: white; text-decoration: none; font-size: 0.875rem; transition: all 0.2s; border: 1px solid rgba(255, 255, 255, 0.2);">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                  <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"></path>
                  <circle cx="12" cy="7" r="4"></circle>
                </svg>
                Account & Settings
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                  <path d="m9 18 6-6-6-6"></path>
                </svg>
              </a>
            </div>
          `
        }
      } else {
        // Don't redirect on auth state checks - only update UI
        // This prevents infinite loops when checking auth state on page load
        console.log('User is not signed in, updating UI only')
        this.onUserSignedOut(false)
      }
    }
  }

  showError(message) {
    console.error(message)
    
    // Display error in error message target if available
    if (this.hasErrorMessageTarget) {
      this.errorMessageTarget.textContent = message
      this.errorMessageTarget.style.display = 'block'
      
      // Auto-hide after 5 seconds
      setTimeout(() => {
        if (this.hasErrorMessageTarget) {
          this.errorMessageTarget.style.display = 'none'
        }
      }, 5000)
    } else {
      // Fallback to alert
      alert(message)
    }
  }

  getErrorMessage(error) {
    const errorMessages = {
      'auth/email-already-in-use': 'This email is already registered.',
      'auth/invalid-email': 'Invalid email address.',
      'auth/operation-not-allowed': 'Email/password authentication is not enabled.',
      'auth/weak-password': 'Password is too weak. Please use a stronger password.',
      'auth/user-disabled': 'This account has been disabled.',
      'auth/user-not-found': 'No account found with this email.',
      'auth/wrong-password': 'Incorrect password.',
      'auth/popup-closed-by-user': 'Sign-in was cancelled.',
      'auth/popup-blocked': 'Popup was blocked. Please allow popups for this site.',
      'auth/network-request-failed': 'Network error. Please check your connection.',
      'auth/too-many-requests': 'Too many failed attempts. Please try again later.'
    }

    return errorMessages[error.code] || error.message || 'An error occurred. Please try again.'
  }
}

