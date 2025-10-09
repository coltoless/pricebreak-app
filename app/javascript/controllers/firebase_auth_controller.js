import { Controller } from "@hotwired/stimulus"

// Firebase Authentication Controller
export default class extends Controller {
  static targets = ["signInButton", "signOutButton", "userInfo", "authForm"]
  static values = { 
    apiKey: String,
    authDomain: String,
    projectId: String
  }

  connect() {
    this.initializeFirebase()
    this.checkAuthState()
  }

  initializeFirebase() {
    // Firebase configuration will be loaded from environment variables
    // or set in the HTML data attributes
    if (typeof firebase !== 'undefined') {
      firebase.initializeApp({
        apiKey: this.apiKeyValue,
        authDomain: this.authDomainValue,
        projectId: this.projectIdValue
      })
      
      this.auth = firebase.auth()
      this.setupAuthStateListener()
    } else {
      console.warn('Firebase SDK not loaded')
    }
  }

  setupAuthStateListener() {
    if (this.auth) {
      this.auth.onAuthStateChanged((user) => {
        if (user) {
          this.onUserSignedIn(user)
        } else {
          this.onUserSignedOut()
        }
      })
    }
  }

  async signInWithGoogle() {
    if (!this.auth) return

    try {
      const provider = new firebase.auth.GoogleAuthProvider()
      const result = await this.auth.signInWithPopup(provider)
      
      if (result.user) {
        // Get the ID token and send it to our Rails backend
        const idToken = await result.user.getIdToken()
        await this.authenticateWithBackend(idToken)
      }
    } catch (error) {
      console.error('Google sign-in error:', error)
      this.showError('Sign-in failed. Please try again.')
    }
  }

  async signOut() {
    if (!this.auth) return

    try {
      await this.auth.signOut()
      this.onUserSignedOut()
    } catch (error) {
      console.error('Sign-out error:', error)
    }
  }

  async authenticateWithBackend(idToken) {
    try {
      const response = await fetch('/api/auth/login', {
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
      } else {
        console.error('Backend authentication failed')
        this.showError('Authentication failed. Please try again.')
      }
    } catch (error) {
      console.error('Backend authentication error:', error)
      this.showError('Authentication failed. Please try again.')
    }
  }

  onUserSignedIn(user) {
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
  }

  updateUserInfo(user) {
    if (this.hasUserInfoTarget) {
      this.userInfoTarget.innerHTML = `
        <div class="user-info">
          <p>Welcome, ${user.name || user.email}!</p>
          <p>Email: ${user.email}</p>
          <p>User ID: ${user.id}</p>
        </div>
      `
    }
  }

  checkAuthState() {
    if (this.auth) {
      const user = this.auth.currentUser
      if (user) {
        this.onUserSignedIn(user)
      } else {
        this.onUserSignedOut()
      }
    }
  }

  showError(message) {
    // Simple error display - you can enhance this
    console.error(message)
    alert(message)
  }
}

