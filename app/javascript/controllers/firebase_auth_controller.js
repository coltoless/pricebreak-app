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
    this.initializeFirebase()
    this.checkAuthState()
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
    if (this.auth) {
      onAuthStateChanged(this.auth, async (user) => {
        if (user) {
          await this.onUserSignedIn(user)
        } else {
          this.onUserSignedOut()
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
      this.onUserSignedOut()
      
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
        this.showError(errorData.error || 'Authentication failed. Please try again.')
      }
    } catch (error) {
      console.error('Backend authentication error:', error)
      this.showError('Authentication failed. Please try again.')
    }
  }

  async onUserSignedIn(user) {
    // Get fresh token and authenticate with backend
    try {
      const idToken = await user.getIdToken()
      await this.authenticateWithBackend(idToken)
    } catch (error) {
      console.error('Failed to get ID token:', error)
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
          <p>Welcome, ${user.displayName || user.email}!</p>
          <p>Email: ${user.email}</p>
        </div>
      `
    }

    // Hide auth form if it exists
    if (this.hasAuthFormTarget) {
      this.authFormTarget.style.display = 'none'
    }
  }

  onUserSignedOut() {
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
    if (this.auth) {
      // onAuthStateChanged will handle this automatically
      // But we can check current state for immediate UI update
      const user = this.auth.currentUser
      if (user) {
        this.onUserSignedIn(user)
      } else {
        this.onUserSignedOut()
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

