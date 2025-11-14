import { Controller } from "@hotwired/stimulus"
import { initializeApp, getApps } from 'firebase/app'
import { getAuth, onAuthStateChanged } from 'firebase/auth'

export default class extends Controller {
  static targets = ["avatar", "greeting", "email", "emailValue", "emailSubscription", "airportsList"]

  connect() {
    this.loadUserData()
  }

  async loadUserData() {
    try {
      // Initialize Firebase if needed
      if (!getApps().length && window.firebaseConfig?.apiKey) {
        const { initializeApp } = await import('firebase/app')
        initializeApp(window.firebaseConfig)
      }
      
      const auth = getAuth()
      
      // Wait for auth state
      onAuthStateChanged(auth, async (user) => {
        if (user) {
          // Get ID token and fetch user data from backend
          try {
            const idToken = await user.getIdToken()
            const response = await fetch('/api/auth/me', {
              headers: {
                'Authorization': `Bearer ${idToken}`,
                'Content-Type': 'application/json'
              }
            })
            
            if (response.ok) {
              const data = await response.json()
              this.updateUserInfo(data.user)
            } else {
              // If backend fails, use Firebase user data
              this.updateUserInfo({
                email: user.email,
                name: user.displayName || user.email?.split('@')[0] || 'User'
              })
            }
          } catch (error) {
            console.error('Error fetching user data:', error)
            // Fallback to Firebase user data
            this.updateUserInfo({
              email: user.email,
              name: user.displayName || user.email?.split('@')[0] || 'User'
            })
          }
        } else {
          // Not logged in, redirect to home
          window.location.href = '/'
        }
      })
    } catch (error) {
      console.error('Error loading user data:', error)
    }
  }

  updateUserInfo(user) {
    // Update avatar initial
    if (this.hasAvatarTarget) {
      const initial = (user.name || user.email || 'U').charAt(0).toUpperCase()
      this.avatarTarget.innerHTML = `<span class="avatar-initial">${initial}</span>`
    }
    
    // Update greeting
    if (this.hasGreetingTarget) {
      this.greetingTarget.textContent = `Hi there!`
    }
    
    // Update email
    if (this.hasEmailTarget) {
      this.emailTarget.textContent = user.email || 'No email'
    }
    
    if (this.hasEmailValueTarget) {
      this.emailValueTarget.textContent = user.email || 'No email'
    }
  }

  addAirport() {
    // TODO: Implement airport addition
    alert('Airport addition feature coming soon!')
  }

  deleteAccount() {
    if (confirm('Are you sure you want to delete your account? This action cannot be undone.')) {
      // TODO: Implement account deletion
      alert('Account deletion feature coming soon!')
    }
  }
}

