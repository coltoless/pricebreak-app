import { Application } from "@hotwired/stimulus"

const application = Application.start()

// Configure Stimulus development experience
application.debug = false
window.Stimulus = application

// Import and register all your controllers from the importmap under controllers/*

// Import all controllers
import DateRangeController from "./date_range_controller"
import FirebaseAuthController from "./firebase_auth_controller"
import FlightSearchController from "./flight_search_controller"
import PriceAlertController from "./price_alert_controller"
import PriceRangeController from "./price_range_controller"

// Register controllers
application.register("date-range", DateRangeController)
application.register("firebase-auth", FirebaseAuthController)
application.register("flight-search", FlightSearchController)
application.register("price-alert", PriceAlertController)
application.register("price-range", PriceRangeController)

export { application }

