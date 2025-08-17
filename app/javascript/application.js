// Entry point for the build script in your package.json
import "@hotwired/turbo-rails"
import "./controllers"

// Import React components - Commented out for coming soon mode
// import React from 'react'
// import { createRoot } from 'react-dom/client'
// import { FlightPriceFilter } from './components'

// Configure your import map in config/importmap.rb

// Initialize React components when DOM is ready - Commented out for coming soon mode
// document.addEventListener('DOMContentLoaded', () => {
//   // Initialize Flight Price Filter if the container exists
//   const flightFilterContainer = document.getElementById('flight-price-filter')
//   if (flightFilterContainer) {
//     const root = createRoot(flightFilterContainer)
//     root.render(
//       <FlightPriceFilter
//         onSaveFilter={(filter) => {
//           console.log('Saving filter:', filter)
//           // Here you can send the filter data to your Rails backend
//           fetch('/api/flight_filters', {
//             method: 'POST',
//             headers: {
//               'Content-Type': 'application/json',
//               'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.getAttribute('content')
//             },
//             body: JSON.stringify(filter)
//           })
//           .then(response => response.json())
//           .then(data => {
//             console.log('Filter saved:', data)
//             alert('Filter saved successfully!')
//           })
//           .catch(error => {
//             console.error('Error saving filter:', error)
//             alert('Error saving filter. Please try again.')
//           })
//         }}
//         onPreviewAlert={(filter) => {
//           console.log('Previewing alert for filter:', filter)
//           alert('Alert preview generated! Check the console for details.')
//         }}
//         onTestAlert={(filter) => {
//           console.log('Testing alert for filter:', filter)
//           alert('Test alert sent! Check your notification methods.')
//         }}
//       />
//     )
//   }
// })

// Coming soon mode - simple console message
document.addEventListener('DOMContentLoaded', () => {
  console.log('PriceBreak - Coming Soon! 🚀')
  console.log('All functionality has been temporarily disabled for the coming soon phase.')
  console.log('Users can only access the landing page and email signup.')
}) 