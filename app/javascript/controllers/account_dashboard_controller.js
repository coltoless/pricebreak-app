import { Controller } from "@hotwired/stimulus"
import { initializeApp, getApps } from 'firebase/app'
import { getAuth, onAuthStateChanged } from 'firebase/auth'

export default class extends Controller {
  static targets = ["avatar", "greeting", "email", "emailValue", "emailSubscription", "airportsList", 
                   "homeCity", "currency", "language", "timezone", "alertsList", "alertsStats", 
                   "savedSearchesList", "futureTripsList", "suggestedAlertsList"]

  connect() {
    this.preferredAirports = []
    this.authChecked = false
    this.redirecting = false
    
    // COMPLETELY DISABLE REDIRECTS - just load data and show message if needed
    console.log('Account dashboard controller connected - redirects DISABLED')
    
    this.loadUserData()
    
    // Listen for checkbox changes
    if (this.hasEmailSubscriptionTarget) {
      this.emailSubscriptionTarget.addEventListener('change', () => {
        this.savePreferences()
      })
    }
  }

  showErrorMessage(message) {
    // Show error message in the page instead of redirecting
    // Check if message already exists to prevent duplicates
    let errorDiv = document.getElementById('account-error-message')
    if (errorDiv) {
      return // Already showing message
    }
    
    errorDiv = document.createElement('div')
    errorDiv.id = 'account-error-message'
    errorDiv.style.cssText = 'position: fixed; top: 20px; left: 50%; transform: translateX(-50%); background: #FEE; border: 2px solid #FCC; padding: 1rem; border-radius: 8px; z-index: 10000; max-width: 500px; box-shadow: 0 4px 6px rgba(0,0,0,0.1);'
    errorDiv.innerHTML = `
      <p style="margin: 0; color: #C33; font-weight: 600;">${message}</p>
      <a href="/" style="display: inline-block; margin-top: 0.5rem; color: #2563EB; text-decoration: underline;">Go to Home</a>
    `
    document.body.appendChild(errorDiv)
    
    // Don't auto-remove - let user dismiss it
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
      await new Promise(resolve => setTimeout(resolve, 1000))
      
      // Check current user first before setting up listener
      const currentUser = auth.currentUser
      if (currentUser) {
        // User is already logged in, load their data
        await this.loadUserDataFromFirebase(currentUser)
        return
      }
      
      // Set up auth state listener - DISABLED REDIRECTS TO PREVENT LOOPS
      const unsubscribe = onAuthStateChanged(auth, async (user) => {
        // Prevent multiple checks
        if (this.redirecting) {
          return
        }
        
        this.authChecked = true
        
        if (user) {
          // User is logged in, load their data
          await this.loadUserDataFromFirebase(user)
        } else {
          // Not logged in - SHOW MESSAGE INSTEAD OF REDIRECTING
          console.log('User not logged in, showing message instead of redirecting')
          this.showErrorMessage('Please sign in to access your account. <a href="/" style="color: #2563EB; text-decoration: underline;">Go to Home</a>')
          
          // DISABLED: No redirect to prevent loops
          // The user can manually navigate away if needed
        }
      })
      
      // Store unsubscribe for cleanup if needed
      this.unsubscribe = unsubscribe
    } catch (error) {
      console.error('Error loading user data:', error)
      // Don't redirect on error - just show error state
      this.showErrorMessage('Error loading account data. Please try refreshing the page.')
    }
  }
  
  async loadUserDataFromFirebase(user) {
    try {
      const idToken = await user.getIdToken()
      
      // Fetch comprehensive dashboard data
      const dashboardResponse = await fetch('/api/auth/dashboard', {
        headers: {
          'Authorization': `Bearer ${idToken}`,
          'Content-Type': 'application/json'
        }
      })
      
      if (dashboardResponse.ok) {
        const dashboardData = await dashboardResponse.json()
        this.preferredAirports = dashboardData.preferences?.preferred_airports || []
        this.updateDashboardData(dashboardData)
        return
      }
      
      // Fallback to basic user data
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
  }
  
  updateDashboardData(data) {
    // Update user info
    this.updateUserInfo({
      email: data.preferences?.email || '',
      name: data.preferences?.name || 'User',
      email_subscription: data.preferences?.email_subscription || false,
      preferred_airports: data.preferences?.preferred_airports || []
    })
    
    // Update preferences
    if (this.hasHomeCityTarget) {
      this.homeCityTarget.value = data.preferences?.home_city || ''
    }
    if (this.hasCurrencyTarget) {
      this.currencyTarget.value = data.preferences?.currency || 'USD'
    }
    if (this.hasLanguageTarget) {
      this.languageTarget.value = data.preferences?.language || 'en'
    }
    if (this.hasTimezoneTarget) {
      this.timezoneTarget.value = data.preferences?.timezone || 'UTC'
    }
    
    // Update alerts
    this.updateAlerts(data.alerts)
    
    // Update saved searches
    this.updateSavedSearches(data.saved_searches || [])
    
    // Update future trips
    this.updateFutureTrips(data.future_trips || [])
    
    // Update suggested alerts
    this.updateSuggestedAlerts(data.suggested_alerts || [])
  }
  
  updateAlerts(alertsData) {
    if (!this.hasAlertsListTarget) return
    
    const alerts = alertsData?.active || []
    const stats = alertsData?.stats || {}
    
    // Update stats
    if (this.hasAlertsStatsTarget) {
      this.alertsStatsTarget.textContent = `${stats.active || 0} active • ${stats.triggered || 0} triggered • ${stats.total || 0} total`
    }
    
    // Update alerts list
    if (alerts.length === 0) {
      this.alertsListTarget.innerHTML = '<p style="color: #9CA3AF;">No active alerts. Create one to get started!</p>'
      return
    }
    
    const alertsHtml = alerts.map(alert => {
      const dateStr = alert.departure_date ? new Date(alert.departure_date).toLocaleDateString() : 'N/A'
      const priceStr = alert.current_price ? `$${alert.current_price.toFixed(2)}` : 'Monitoring...'
      const targetPriceStr = `$${alert.target_price.toFixed(2)}`
      const urgentBadge = alert.is_urgent ? '<span style="background: #DC2626; color: white; padding: 0.25rem 0.5rem; border-radius: 0.25rem; font-size: 0.75rem; margin-left: 0.5rem;">Urgent</span>' : ''
      
      return `
        <div style="background: rgba(255, 255, 255, 0.05); border-radius: 0.5rem; padding: 1rem; margin-bottom: 0.75rem; border: 1px solid rgba(255, 255, 255, 0.1);">
          <div style="display: flex; justify-content: space-between; align-items: start; margin-bottom: 0.5rem;">
            <div>
              <div style="color: white; font-weight: 600; font-size: 1rem;">${alert.route_description || `${alert.origin} → ${alert.destination}`} ${urgentBadge}</div>
              <div style="color: #9CA3AF; font-size: 0.875rem; margin-top: 0.25rem;">Departure: ${dateStr}</div>
            </div>
            <div style="text-align: right;">
              <div style="color: white; font-weight: 600;">${priceStr}</div>
              <div style="color: #9CA3AF; font-size: 0.875rem;">Target: ${targetPriceStr}</div>
            </div>
          </div>
          <div style="display: flex; gap: 0.5rem; margin-top: 0.75rem;">
            <span style="background: rgba(255, 255, 255, 0.1); padding: 0.25rem 0.5rem; border-radius: 0.25rem; font-size: 0.75rem; color: #9CA3AF;">${alert.status}</span>
            <span style="background: rgba(255, 255, 255, 0.1); padding: 0.25rem 0.5rem; border-radius: 0.25rem; font-size: 0.75rem; color: #9CA3AF;">${alert.notification_method}</span>
          </div>
        </div>
      `
    }).join('')
    
    this.alertsListTarget.innerHTML = alertsHtml
  }
  
  updateSavedSearches(searches) {
    if (!this.hasSavedSearchesListTarget) return
    
    if (searches.length === 0) {
      this.savedSearchesListTarget.innerHTML = '<p style="color: #9CA3AF;">No saved searches yet. Save a search to see it here!</p>'
      return
    }
    
    const searchesHtml = searches.map(search => {
      const activeBadge = search.is_active 
        ? '<span style="background: #059669; color: white; padding: 0.25rem 0.5rem; border-radius: 0.25rem; font-size: 0.75rem; margin-left: 0.5rem;">Active</span>'
        : '<span style="background: #6B7280; color: white; padding: 0.25rem 0.5rem; border-radius: 0.25rem; font-size: 0.75rem; margin-left: 0.5rem;">Inactive</span>'
      const dateStr = search.created_at ? new Date(search.created_at).toLocaleDateString() : 'N/A'
      
      return `
        <div style="background: rgba(255, 255, 255, 0.05); border-radius: 0.5rem; padding: 1rem; margin-bottom: 0.75rem; border: 1px solid rgba(255, 255, 255, 0.1);">
          <div style="display: flex; justify-content: space-between; align-items: start; margin-bottom: 0.5rem;">
            <div>
              <div style="color: white; font-weight: 600; font-size: 1rem;">${search.name || 'Unnamed Search'} ${activeBadge}</div>
              <div style="color: #9CA3AF; font-size: 0.875rem; margin-top: 0.25rem;">${search.route_description || 'No route'}</div>
            </div>
            <div style="text-align: right;">
              <div style="color: #9CA3AF; font-size: 0.875rem;">Created: ${dateStr}</div>
            </div>
          </div>
          <div style="display: flex; gap: 0.5rem; margin-top: 0.75rem; flex-wrap: wrap;">
            <span style="background: rgba(255, 255, 255, 0.1); padding: 0.25rem 0.5rem; border-radius: 0.25rem; font-size: 0.75rem; color: #9CA3AF;">${search.trip_type}</span>
            <span style="background: rgba(255, 255, 255, 0.1); padding: 0.25rem 0.5rem; border-radius: 0.25rem; font-size: 0.75rem; color: #9CA3AF;">${search.passenger_count} passengers</span>
            <span style="background: rgba(255, 255, 255, 0.1); padding: 0.25rem 0.5rem; border-radius: 0.25rem; font-size: 0.75rem; color: #9CA3AF;">${search.cabin_class}</span>
            ${search.target_price > 0 ? `<span style="background: rgba(255, 255, 255, 0.1); padding: 0.25rem 0.5rem; border-radius: 0.25rem; font-size: 0.75rem; color: #9CA3AF;">Target: $${search.target_price.toFixed(2)}</span>` : ''}
          </div>
        </div>
      `
    }).join('')
    
    this.savedSearchesListTarget.innerHTML = searchesHtml
  }
  
  updateFutureTrips(trips) {
    if (!this.hasFutureTripsListTarget) return
    
    if (trips.length === 0) {
      this.futureTripsListTarget.innerHTML = '<p style="color: #9CA3AF;">No future trips planned. Add a trip to get AI insights and suggested alerts!</p>'
      return
    }
    
    const tripsHtml = trips.map(trip => {
      const urgentBadge = trip.is_urgent ? '<span style="background: #DC2626; color: white; padding: 0.25rem 0.5rem; border-radius: 0.25rem; font-size: 0.75rem; margin-left: 0.5rem;">Urgent</span>' : ''
      const earliestDate = trip.departure_dates && trip.departure_dates.length > 0 
        ? new Date(trip.departure_dates[0]).toLocaleDateString() 
        : 'N/A'
      
      return `
        <div style="background: rgba(255, 255, 255, 0.05); border-radius: 0.5rem; padding: 1rem; margin-bottom: 0.75rem; border: 1px solid rgba(255, 255, 255, 0.1);">
          <div style="display: flex; justify-content: space-between; align-items: start; margin-bottom: 0.5rem;">
            <div>
              <div style="color: white; font-weight: 600; font-size: 1rem;">${trip.name || 'Unnamed Trip'} ${urgentBadge}</div>
              <div style="color: #9CA3AF; font-size: 0.875rem; margin-top: 0.25rem;">${trip.route_description || 'No route'}</div>
            </div>
            <div style="text-align: right;">
              <div style="color: white; font-weight: 600;">${earliestDate}</div>
              <div style="color: #9CA3AF; font-size: 0.875rem;">Departure</div>
            </div>
          </div>
          <div style="display: flex; gap: 0.5rem; margin-top: 0.75rem; flex-wrap: wrap;">
            <span style="background: rgba(37, 99, 235, 0.2); padding: 0.25rem 0.5rem; border-radius: 0.25rem; font-size: 0.75rem; color: #93C5FD;">AI Insights Available</span>
            <span style="background: rgba(255, 255, 255, 0.1); padding: 0.25rem 0.5rem; border-radius: 0.25rem; font-size: 0.75rem; color: #9CA3AF;">${trip.trip_type}</span>
            ${trip.target_price > 0 ? `<span style="background: rgba(255, 255, 255, 0.1); padding: 0.25rem 0.5rem; border-radius: 0.25rem; font-size: 0.75rem; color: #9CA3AF;">Target: $${trip.target_price.toFixed(2)}</span>` : ''}
          </div>
        </div>
      `
    }).join('')
    
    this.futureTripsListTarget.innerHTML = tripsHtml
  }
  
  updateSuggestedAlerts(suggestions) {
    if (!this.hasSuggestedAlertsListTarget) return
    
    if (suggestions.length === 0) {
      this.suggestedAlertsListTarget.innerHTML = '<p style="color: #9CA3AF;">No suggestions at this time. Keep searching to get personalized alert suggestions!</p>'
      return
    }
    
    const suggestionsHtml = suggestions.map((suggestion, index) => {
      const priorityColor = suggestion.priority === 'high' ? '#DC2626' : suggestion.priority === 'medium' ? '#D97706' : '#6B7280'
      
      return `
        <div style="background: rgba(255, 255, 255, 0.05); border-radius: 0.5rem; padding: 1rem; margin-bottom: 0.75rem; border: 1px solid rgba(255, 255, 255, 0.1);">
          <div style="display: flex; justify-content: space-between; align-items: start; margin-bottom: 0.5rem;">
            <div>
              <div style="color: white; font-weight: 600; font-size: 1rem;">${suggestion.origin} → ${suggestion.destination}</div>
              <div style="color: #9CA3AF; font-size: 0.875rem; margin-top: 0.25rem;">${suggestion.reason}</div>
            </div>
            <div style="text-align: right;">
              <span style="background: ${priorityColor}; color: white; padding: 0.25rem 0.5rem; border-radius: 0.25rem; font-size: 0.75rem; text-transform: capitalize;">${suggestion.priority}</span>
            </div>
          </div>
          ${suggestion.suggested_target_price ? `
            <div style="margin-top: 0.75rem;">
              <div style="color: #9CA3AF; font-size: 0.875rem; margin-bottom: 0.25rem;">Suggested target price: $${suggestion.suggested_target_price.toFixed(2)}</div>
              <button onclick="alert('Create alert feature coming soon!')" 
                      style="padding: 0.5rem 1rem; background: #2563EB; border: none; border-radius: 0.375rem; color: white; cursor: pointer; font-size: 0.875rem; font-weight: 500;">
                Create Alert
              </button>
            </div>
          ` : ''}
        </div>
      `
    }).join('')
    
    this.suggestedAlertsListTarget.innerHTML = suggestionsHtml
  }
  
  disconnect() {
    if (this.unsubscribe) {
      this.unsubscribe()
    }
  }

  updateUserInfo(user) {
    // Update avatar initial with color
    if (this.hasAvatarTarget) {
      const name = user.name || user.email?.split('@')[0] || 'User';
      const initial = name.charAt(0).toUpperCase();
      // Generate consistent color based on first letter
      const colors = ['#2563EB', '#7C3AED', '#DC2626', '#059669', '#D97706', '#BE185D', '#0891B2', '#CA8A04'];
      const colorIndex = initial.charCodeAt(0) % colors.length;
      const avatarColor = colors[colorIndex];
      
      this.avatarTarget.style.background = avatarColor;
      this.avatarTarget.textContent = initial;
    }
    
    // Update greeting
    if (this.hasGreetingTarget) {
      const name = user.name || user.email?.split('@')[0] || 'User';
      this.greetingTarget.textContent = `Hello, ${name}!`;
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
    
    // Show logout button
    const logoutBtn = document.querySelector('.account-logout-btn')
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
      const homeCity = this.hasHomeCityTarget ? this.homeCityTarget.value : null
      const currency = this.hasCurrencyTarget ? this.currencyTarget.value : null
      const language = this.hasLanguageTarget ? this.languageTarget.value : null
      const timezone = this.hasTimezoneTarget ? this.timezoneTarget.value : null
      
      const response = await fetch('/api/auth/preferences', {
        method: 'PUT',
        headers: {
          'Authorization': `Bearer ${idToken}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          email_subscription: emailSubscription,
          preferred_airports: preferredAirports,
          home_city: homeCity,
          currency: currency,
          language: language,
          timezone: timezone
        })
      })
      
      if (response.ok) {
        // Show success message
        const button = document.querySelector('button[data-action*="savePreferences"]')
        if (button) {
          const originalText = button.textContent
          button.textContent = 'Saved!'
          button.style.background = '#059669'
          setTimeout(() => {
            button.textContent = originalText
            button.style.background = '#2563EB'
          }, 2000)
        }
      } else {
        console.error('Failed to save preferences')
        alert('Failed to save preferences. Please try again.')
      }
    } catch (error) {
      console.error('Error saving preferences:', error)
      alert('Error saving preferences. Please try again.')
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

  async signOut() {
    try {
      const auth = getAuth()
      if (auth.currentUser) {
        const { signOut } = await import('firebase/auth')
        await signOut(auth)
        
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
        }
        
        // Update UI without redirect to prevent loops
        // Just show a message that user is signed out
        this.showErrorMessage('You have been signed out. <a href="/" style="color: #2563EB; text-decoration: underline;">Go to Home</a>')
        
        // Clear user data display
        if (this.hasGreetingTarget) {
          this.greetingTarget.textContent = 'Not signed in'
        }
        if (this.hasEmailTarget) {
          this.emailTarget.textContent = ''
        }
        
        // DISABLED: No redirect to prevent refresh loops
        // window.location.href = '/'
      }
    } catch (error) {
      console.error('Sign-out error:', error)
    }
  }

  deleteAccount() {
    if (confirm('Are you sure you want to delete your account? This action cannot be undone.')) {
      // TODO: Implement account deletion
      alert('Account deletion feature coming soon!')
    }
  }
}

