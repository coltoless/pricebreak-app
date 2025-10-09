import { Controller } from "@hotwired/stimulus"
import { createRoot } from 'react-dom/client'
import React from 'react'
import FlightSearchInterface from '../components/FlightSearchInterface'

// Connects to data-controller="flight-search"
export default class extends Controller {
  static targets = ["container"]
  static values = { 
    filters: Array,
    alerts: Array,
    user: Object
  }

  connect() {
    console.log("Flight search controller connected")
    this.initializeReactComponent()
  }

  disconnect() {
    if (this.reactRoot) {
      this.reactRoot.unmount()
    }
  }

  initializeReactComponent() {
    if (this.hasContainerTarget) {
      this.reactRoot = createRoot(this.containerTarget)
      
      this.reactRoot.render(
        React.createElement(FlightSearchInterface, {
          onFilterChange: (filter) => this.handleFilterChange(filter),
          onSaveFilter: (filter) => this.handleSaveFilter(filter),
          onTestAlert: (filter) => this.handleTestAlert(filter),
          initialFilters: this.filtersValue || [],
          user: this.userValue || null
        })
      )
    }
  }

  handleFilterChange(filter) {
    console.log('Filter changed:', filter)
    
    // Emit custom event for other controllers to listen to
    this.dispatch('filterChanged', { 
      detail: { filter: filter },
      bubbles: true 
    })

    // Update URL params for bookmarking
    this.updateUrlParams(filter)
  }

  handleSaveFilter(filter) {
    console.log('Saving filter:', filter)
    
    // Show loading state
    this.dispatch('saving', { 
      detail: { filter: filter },
      bubbles: true 
    })

    // Send to Rails API
    this.saveFilterToAPI(filter)
      .then(response => {
        this.dispatch('saved', { 
          detail: { filter: response, success: true },
          bubbles: true 
        })
      })
      .catch(error => {
        console.error('Error saving filter:', error)
        this.dispatch('saveError', { 
          detail: { error: error, filter: filter },
          bubbles: true 
        })
      })
  }

  handleTestAlert(filter) {
    console.log('Testing alert for filter:', filter)
    
    // Send test alert request to API
    this.testAlertAPI(filter)
      .then(response => {
        this.dispatch('alertTested', { 
          detail: { success: true, response: response },
          bubbles: true 
        })
      })
      .catch(error => {
        console.error('Error testing alert:', error)
        this.dispatch('alertTestError', { 
          detail: { error: error },
          bubbles: true 
        })
      })
  }

  async saveFilterToAPI(filter) {
    const response = await fetch('/api/flight_filters', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({
        flight_filter: {
          name: filter.filterName || 'Untitled Filter',
          description: filter.description || '',
          trip_type: filter.tripType,
          flexible_dates: filter.flexibleDates,
          date_flexibility: filter.dateFlexibility,
          origin_airports: filter.origin ? [filter.origin.code] : [],
          destination_airports: filter.destination ? [filter.destination.code] : [],
          departure_dates: filter.departureDate ? [filter.departureDate.toISOString().split('T')[0]] : [],
          return_dates: filter.returnDate ? [filter.returnDate.toISOString().split('T')[0]] : [],
          passenger_details: filter.passengers,
          price_parameters: {
            target_price: filter.targetPrice,
            max_price: filter.budgetRange?.max || 1000,
            min_price: filter.budgetRange?.min || 0,
            currency: filter.currency
          },
          advanced_preferences: {
            cabin_class: filter.cabinClass,
            max_stops: filter.maxStops,
            airline_preferences: filter.airlinePreferences || [],
            preferred_times: filter.preferredTimes || { departure: [], arrival: [] }
          },
          alert_settings: {
            monitor_frequency: filter.monitorFrequency,
            notification_methods: filter.notificationMethods,
            price_drop_threshold: filter.priceDropPercentage,
            alert_urgency: filter.alertUrgency,
            instant_alert_priority: filter.instantAlertPriority,
            alert_detail_level: filter.alertDetailLevel,
            instant_price_break_alerts: filter.instantPriceBreakAlerts,
            price_break_confidence: filter.priceBreakConfidence
          },
          is_active: filter.isActive
        }
      })
    })

    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`)
    }

    return await response.json()
  }

  async testAlertAPI(filter) {
    const response = await fetch('/api/flight_alerts/test', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({
        filter: filter
      })
    })

    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`)
    }

    return await response.json()
  }

  updateUrlParams(filter) {
    const url = new URL(window.location)
    
    // Update URL parameters based on filter
    if (filter.origin) {
      url.searchParams.set('from', filter.origin.code)
    }
    if (filter.destination) {
      url.searchParams.set('to', filter.destination.code)
    }
    if (filter.departureDate) {
      url.searchParams.set('depart', filter.departureDate.toISOString().split('T')[0])
    }
    if (filter.returnDate) {
      url.searchParams.set('return', filter.returnDate.toISOString().split('T')[0])
    }
    if (filter.tripType) {
      url.searchParams.set('trip', filter.tripType)
    }
    if (filter.passengers) {
      url.searchParams.set('passengers', JSON.stringify(filter.passengers))
    }
    if (filter.cabinClass) {
      url.searchParams.set('cabin', filter.cabinClass)
    }

    // Update URL without page reload
    window.history.replaceState({}, '', url)
  }

  // Action to refresh filters from server
  refreshFilters() {
    fetch('/api/flight_filters')
      .then(response => response.json())
      .then(data => {
        this.filtersValue = data.filters
        this.dispatch('filtersRefreshed', { 
          detail: { filters: data.filters },
          bubbles: true 
        })
      })
      .catch(error => {
        console.error('Error refreshing filters:', error)
      })
  }

  // Action to clear all filters
  clearFilters() {
    this.dispatch('clearFilters', { bubbles: true })
  }

  // Action to export filters
  exportFilters() {
    const filters = this.filtersValue || []
    const dataStr = JSON.stringify(filters, null, 2)
    const dataBlob = new Blob([dataStr], { type: 'application/json' })
    
    const link = document.createElement('a')
    link.href = URL.createObjectURL(dataBlob)
    link.download = 'pricebreak-filters.json'
    link.click()
  }
}

