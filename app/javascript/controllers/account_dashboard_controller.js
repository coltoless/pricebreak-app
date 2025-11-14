import { Controller } from "@hotwired/stimulus"
import { initializeApp, getApps } from 'firebase/app'
import { getAuth, onAuthStateChanged } from 'firebase/auth'

export default class extends Controller {
  static targets = ["avatar", "greeting", "email", "emailValue", "emailSubscription", "airportsList"]

  connect() {
    this.preferredAirports = []
    this.authChecked = false
    this.redirecting = false
    this.loadUserData()
    
    // Listen for checkbox changes
    if (this.hasEmailSubscriptionTarget) {
      this.emailSubscriptionTarget.addEventListener('change', () => {
        this.savePreferences()
      })
    }
  }

  async loadUserData() {
    try {
      // Initialize Firebase if needed
      if (!getApps().length && window.firebaseConfig?.apiKey) {
        const { initializeApp } = await import('firebase/app')
        initializeApp(window.firebaseConfig)
      }
      
      const auth = getAuth()
      
      // Wait a bit for Firebase to initialize
      await new Promise(resolve => setTimeout(resolve, 500))
      
      // Wait for auth state - use a timeout to prevent infinite loops
      const authCheckTimeout = setTimeout(() => {
        if (!this.authChecked && !this.redirecting) {
          console.warn('Auth check timeout - user may not be logged in')
          this.redirecting = true
          // Only redirect if we're on the account page
          if (window.location.pathname === '/account' || window.location.pathname.startsWith('/account/')) {
            window.location.href = '/'
          }
        }
      }, 3000) // 3 second timeout
      
      const unsubscribe = onAuthStateChanged(auth, async (user) => {
        // Clear timeout since we got a response
        clearTimeout(authCheckTimeout)
        
        // Prevent multiple redirects
        if (this.redirecting) {
          return
        }
        
        this.authChecked = true
        
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
              this.preferredAirports = data.user.preferred_airports || []
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
          // Not logged in - only redirect if we're on account page
          if (!this.redirecting && (window.location.pathname === '/account' || window.location.pathname.startsWith('/account/'))) {
            this.redirecting = true
            // Small delay to prevent immediate redirect loops
            setTimeout(() => {
              if (window.location.pathname === '/account' || window.location.pathname.startsWith('/account/')) {
                window.location.href = '/'
              }
            }, 100)
          }
        }
      })
      
      // Store unsubscribe for cleanup if needed
      this.unsubscribe = unsubscribe
    } catch (error) {
      console.error('Error loading user data:', error)
      // Don't redirect on error - just show error state
    }
  }
  
  disconnect() {
    if (this.unsubscribe) {
      this.unsubscribe()
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
    
    // Update email subscription checkbox
    if (this.hasEmailSubscriptionTarget) {
      this.emailSubscriptionTarget.checked = user.email_subscription || false
    }
    
    // Update preferred airports
    if (this.hasAirportsListTarget) {
      this.updateAirportsList(user.preferred_airports || [])
    }
    
    // Show logout button (it's controlled by firebase-auth controller, but we can ensure it's visible)
    const logoutBtn = document.querySelector('[data-firebase-auth-target="signOutButton"]')
    if (logoutBtn) {
      logoutBtn.style.display = 'block'
    }
  }
  
  updateAirportsList(airports) {
    if (!this.hasAirportsListTarget) return
    
    // Update the instance variable
    this.preferredAirports = airports
    
    if (airports.length === 0) {
      this.airportsListTarget.innerHTML = ''
      return
    }
    
    const airportsHtml = airports.map((airport, index) => {
      const airportName = typeof airport === 'string' ? airport : (airport.name || airport.code || airport)
      return `
        <div class="account-airport-item" style="display: flex; align-items: center; justify-content: space-between; padding: 0.5rem; background: #F9FAFB; border-radius: 0.375rem; margin-bottom: 0.5rem;">
          <span style="font-size: 0.875rem; color: #374151;">${airportName}</span>
          <button class="account-remove-airport" data-airport-index="${index}" data-action="click->account-dashboard#removeAirport" style="background: none; border: none; color: #EF4444; cursor: pointer; padding: 0.25rem;">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M18 6L6 18M6 6l12 12"></path>
            </svg>
          </button>
        </div>
      `
    }).join('')
    
    this.airportsListTarget.innerHTML = airportsHtml
  }
  
  async savePreferences() {
    try {
      const auth = getAuth()
      const user = auth.currentUser
      if (!user) return
      
      const idToken = await user.getIdToken()
      const emailSubscription = this.hasEmailSubscriptionTarget ? this.emailSubscriptionTarget.checked : false
      const preferredAirports = this.preferredAirports || []
      
      const response = await fetch('/api/auth/preferences', {
        method: 'PUT',
        headers: {
          'Authorization': `Bearer ${idToken}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          email_subscription: emailSubscription,
          preferred_airports: preferredAirports
        })
      })
      
      if (!response.ok) {
        console.error('Failed to save preferences')
      }
    } catch (error) {
      console.error('Error saving preferences:', error)
    }
  }
  
  removeAirport(event) {
    event.preventDefault()
    const index = parseInt(event.currentTarget.dataset.airportIndex)
    if (isNaN(index)) return
    
    if (!this.preferredAirports || this.preferredAirports.length === 0) {
      return
    }
    
    // Create a new array without the removed airport
    const updatedAirports = [...this.preferredAirports]
    updatedAirports.splice(index, 1)
    
    this.updateAirportsList(updatedAirports)
    this.savePreferences()
  }

  addAirport() {
    // Simple prompt for now - can be enhanced with autocomplete later
    const airportCode = prompt('Enter airport code (e.g., JFK, LAX):')
    if (airportCode && airportCode.trim()) {
      if (!this.preferredAirports) {
        this.preferredAirports = []
      }
      
      // Limit to 6 airports
      if (this.preferredAirports.length >= 6) {
        alert('You can only add up to 6 departure airports.')
        return
      }
      
      // Check if already added
      if (this.preferredAirports.includes(airportCode.toUpperCase())) {
        alert('This airport is already in your list.')
        return
      }
      
      this.preferredAirports.push(airportCode.toUpperCase())
      this.updateAirportsList(this.preferredAirports)
      this.savePreferences()
    }
  }

  deleteAccount() {
    if (confirm('Are you sure you want to delete your account? This action cannot be undone.')) {
      // TODO: Implement account deletion
      alert('Account deletion feature coming soon!')
    }
  }
}

