// Import Rails and Stimulus
// TEMPORARILY DISABLED TURBO TO DEBUG REFRESH LOOP
// import "@hotwired/turbo-rails"
import "./controllers"

// Import Firebase early to ensure it's initialized and available globally
import './lib/firebase'

// Import React and components
import React from 'react'
import { createRoot } from 'react-dom/client'

// Import our components
import FlightSearchInterface from './components/FlightSearchInterface'
import AirportAutocompleteTest from './components/AirportAutocompleteTest'
import SimpleTest from './components/SimpleTest'

// Export FirebaseUI initialization for use in views
export { initializeFirebaseUI } from './lib/firebaseui'
export { showSignInPopup } from './lib/signInPopup'
// Export Firebase initialization function
export { initializeFirebaseApp } from './lib/firebase'

console.log('🚀 priceBreak - JavaScript loading with React support...')

// Initialize when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
  console.log('✅ DOM Content Loaded')
  
  // Mount Simple Test first to verify React works
  const flightFilterContainer = document.getElementById('flight-search-interface')
  if (flightFilterContainer) {
    console.log('✅ Found flight-search-interface container')
    console.log('✅ Mounting Simple Test component...')
    try {
      const root = createRoot(flightFilterContainer)
      root.render(React.createElement(SimpleTest))
      console.log('✅ Simple Test component mounted successfully')
    } catch (error) {
      console.error('❌ Error mounting Simple Test:', error)
      console.error('❌ Error stack:', error.stack)
      flightFilterContainer.innerHTML = `<div style="padding: 20px; background: #fed7d7; border: 2px solid #e53e3e; border-radius: 8px; color: #c53030;"><h2>❌ React Error</h2><p>Error: ${error.message}</p><pre>${error.stack}</pre></div>`
    }
  } else {
    console.log('❌ flight-search-interface container not found')
  }
  
  // Mount Airport Autocomplete Test
  const airportTestContainer = document.getElementById('airport-autocomplete-test')
  if (airportTestContainer) {
    console.log('✅ Found airport-autocomplete-test container')
    console.log('✅ Mounting Airport Autocomplete Test...')
    try {
      const root = createRoot(airportTestContainer)
      root.render(React.createElement(AirportAutocompleteTest))
      console.log('✅ Airport Autocomplete Test mounted successfully')
    } catch (error) {
      console.error('❌ Error mounting Airport Autocomplete Test:', error)
      console.error('❌ Error stack:', error.stack)
      airportTestContainer.innerHTML = `<div style="padding: 20px; background: #fed7d7; border: 2px solid #e53e3e; border-radius: 8px; color: #c53030;"><h2>❌ React Error</h2><p>Error: ${error.message}</p><pre>${error.stack}</pre></div>`
    }
  } else {
    console.log('❌ airport-autocomplete-test container not found')
  }
}) 