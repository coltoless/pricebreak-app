import { Controller } from "@hotwired/stimulus"
import React from "react"
import { createRoot } from "react-dom/client"
import FlightPriceFilter from "../components/FlightPriceFilter"

export default class extends Controller {
  static targets = ["container"]
  static values = {
    initialFilter: Object,
    filterId: Number
  }

  connect() {
    console.log('🔌 FlightFilterController: Connected!')
    console.log('🔌 Has container target:', this.hasContainerTarget)
    console.log('🔌 Container element:', this.containerTarget)
    this.mountReactComponent()
  }

  disconnect() {
    if (this.reactRoot) {
      this.reactRoot.unmount()
    }
  }

  mountReactComponent() {
    if (this.hasContainerTarget) {
      console.log('✅ FlightFilterController: Mounting React component...')
      try {
        this.reactRoot = createRoot(this.containerTarget)
        
        this.reactRoot.render(
          React.createElement(FlightPriceFilter, {
            onSaveFilter: (filter) => this.handleSaveFilter(filter),
            onPreviewAlert: (filter) => this.handlePreviewAlert(filter),
            onTestAlert: (filter) => this.handleTestAlert(filter),
            initialFilter: this.initialFilterValue || {}
          })
        )
        console.log('✅ FlightFilterController: React component mounted successfully')
      } catch (error) {
        console.error('❌ FlightFilterController: Error mounting React component:', error)
        this.containerTarget.innerHTML = `
          <div style="padding: 20px; background: #fed7d7; border: 2px solid #e53e3e; border-radius: 8px; color: #c53030;">
            <h2>❌ React Component Error</h2>
            <p>Error: ${error.message}</p>
            <pre>${error.stack}</pre>
          </div>
        `
      }
    } else {
      console.error('❌ FlightFilterController: Container target not found')
    }
  }

  handleSaveFilter(filter) {
    // Convert React filter format to Rails format
    const formData = this.convertFilterToFormData(filter)
    
    // Submit via fetch API or form submission
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content')
    
    fetch('/flight_filters', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': csrfToken,
        'Accept': 'application/json'
      },
      body: JSON.stringify({
        flight_filter: formData
      })
    })
    .then(response => {
      if (!response.ok) {
        return response.json().then(err => {
          throw new Error(err.errors ? Object.values(err.errors).flat().join(', ') : 'Failed to save filter')
        })
      }
      return response.json()
    })
    .then(data => {
      if (data.id || data.success) {
        const filterId = data.id || data.filter?.id
        if (filterId) {
          window.location.href = `/flight_filters/${filterId}`
        } else {
          alert('Filter saved successfully!')
        }
      } else if (data.errors) {
        alert('Error creating filter: ' + Object.values(data.errors).flat().join(', '))
      }
    })
    .catch(error => {
      console.error('Error:', error)
      alert('Error saving filter: ' + (error.message || 'Please try again.'))
    })
  }

  handlePreviewAlert(filter) {
    // Preview is handled by the React component via modal
    // This is just a placeholder for the callback
    console.log('Preview alert for filter:', filter)
  }

  handleTestAlert(filter) {
    // Convert filter to form data and send test request
    const formData = this.convertFilterToFormData(filter)
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content')
    
    // First save the filter if it doesn't have an ID, then test
    if (!this.filterIdValue) {
      // Save filter first
      fetch('/flight_filters', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': csrfToken,
          'Accept': 'application/json'
        },
        body: JSON.stringify({
          flight_filter: formData
        })
      })
      .then(response => response.json())
      .then(data => {
        if (data.id) {
          // Now test the alert
          this.performTestAlert(data.id)
        } else {
          alert('Error: Could not save filter. Please try again.')
        }
      })
      .catch(error => {
        console.error('Error:', error)
        alert('Error saving filter. Please try again.')
      })
    } else {
      // Filter already exists, just test
      this.performTestAlert(this.filterIdValue)
    }
  }

  performTestAlert(filterId) {
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content')
    
    // Show loading indicator
    const loadingMessage = document.createElement('div')
    loadingMessage.className = 'fixed top-4 right-4 bg-blue-600 text-white px-6 py-3 rounded-lg shadow-lg z-50'
    loadingMessage.innerHTML = '🔄 Testing price check... This may take a moment.'
    document.body.appendChild(loadingMessage)

    fetch(`/flight_filters/${filterId}/test_price_check`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': csrfToken,
        'Accept': 'application/json'
      }
    })
    .then(response => {
      if (!response.ok) {
        return response.json().then(err => {
          throw new Error(err.error || 'Failed to test alert')
        })
      }
      return response.json()
    })
    .then(data => {
      if (loadingMessage.parentElement) {
        document.body.removeChild(loadingMessage)
      }
      
      if (data.success) {
        // Show success message with results
        const resultsMessage = document.createElement('div')
        resultsMessage.className = 'fixed top-4 right-4 bg-green-600 text-white px-6 py-3 rounded-lg shadow-lg z-50 max-w-md'
        resultsMessage.innerHTML = `
          <div class="font-bold mb-2">✅ Test Alert Complete!</div>
          <div class="text-sm">
            <p><strong>Route:</strong> ${data.route || 'N/A'}</p>
            <p><strong>Latest Prices Found:</strong> ${data.latest_prices?.length || 0}</p>
            <p><strong>Alerts Triggered:</strong> ${data.alerts_triggered || 0}</p>
            ${data.monitoring_result?.error ? `<p class="text-yellow-200"><strong>Note:</strong> ${data.monitoring_result.error}</p>` : ''}
          </div>
          <button onclick="this.parentElement.remove()" class="mt-2 text-xs underline hover:text-gray-200">Close</button>
        `
        document.body.appendChild(resultsMessage)
        
        // Auto-remove after 10 seconds
        setTimeout(() => {
          if (resultsMessage.parentElement) {
            document.body.removeChild(resultsMessage)
          }
        }, 10000)
      } else {
        alert('Test alert completed but no results were found. This is normal if there are no matching flights yet.')
      }
    })
    .catch(error => {
      if (loadingMessage.parentElement) {
        document.body.removeChild(loadingMessage)
      }
      console.error('Error:', error)
      alert('Error testing alert: ' + (error.message || 'Please try again later.'))
    })
  }

  convertFilterToFormData(filter) {
    const formatArray = (arr) => {
      return JSON.stringify(arr)
    }
    
    return {
      name: filter.filterName || 'Untitled Filter',
      description: filter.description || '',
      trip_type: filter.tripType || 'round-trip',
      origin_airports: filter.origin ? formatArray([filter.origin.iata_code]) : '[]',
      destination_airports: filter.destination ? formatArray([filter.destination.iata_code]) : '[]',
      departure_dates: filter.departureDate ? formatArray([filter.departureDate.toISOString().split('T')[0]]) : '[]',
      return_dates: filter.returnDate ? formatArray([filter.returnDate.toISOString().split('T')[0]]) : '[]',
      flexible_dates: filter.flexibleDates || false,
      date_flexibility: filter.dateFlexibility || 3,
      passenger_details: {
        adults: filter.passengers?.adults || 1,
        children: filter.passengers?.children || 0,
        infants: filter.passengers?.infants || 0
      },
      advanced_preferences: {
        cabin_class: filter.cabinClass || 'economy',
        max_stops: filter.maxStops || 'any',
        airline_preferences: filter.airlinePreferences || [],
        preferred_times: filter.preferredTimes || { departure: [], arrival: [] }
      },
      price_parameters: {
        target_price: filter.targetPrice || 0,
        min_price: filter.budgetRange?.min || 0,
        max_price: filter.budgetRange?.max || 1000,
        currency: filter.currency || 'USD'
      },
      alert_settings: {
        monitor_frequency: filter.monitorFrequency || 'daily',
        price_drop_threshold: filter.priceDropPercentage || 10,
        notification_methods: filter.notificationMethods || { email: true, sms: false, push: true, browser: true }
      },
      is_active: filter.isActive !== false
    }
  }
}

