# Commented out for coming soon mode (production)
# class Api::FlightFiltersController < ApplicationController
#   skip_before_action :verify_authenticity_token, only: [:create]

#   def create
#     # For now, just log the filter data and return success
#     # In production, you'd save this to your database
#     Rails.logger.info "Flight Filter received: #{params.inspect}"

#     render json: {
#       success: true,
#       message: 'Filter saved successfully',
#       filter_id: SecureRandom.uuid
#     }
#   end

#   def index
#     # Return list of saved filters (placeholder for now)
#     render json: { filters: [] }
#   end

#   def show
#     # Return specific filter (placeholder for now)
#     render json: { filter: {} }
#   end

#   def destroy
#     # Delete filter (placeholder for now)
#     render json: { success: true, message: 'Filter deleted' }
#   end
# end

# ENABLED for local development
class Api::FlightFiltersController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:create, :update, :destroy]
  before_action :set_flight_filter, only: [:show, :update, :destroy]

  def index
    # For now, return all filters (in production, filter by current_user)
    filters = FlightFilter.includes(:flight_alerts).order(created_at: :desc)
    
    render json: {
      success: true,
      filters: filters.map { |filter| filter_to_json(filter) },
      meta: {
        total_count: filters.count,
        active_count: filters.active.count,
        inactive_count: filters.inactive.count
      }
    }
  end

  def show
    render json: {
      success: true,
      filter: filter_to_json(@flight_filter, include_details: true)
    }
  end

  def create
    service = FlightFilterService.new
    
    # For testing, create a mock user or use a default user
    # In production: user = current_user
    user = User.first # Temporary for testing
    
    result = service.create_filter(flight_filter_params, user)
    
    if result[:success]
      render json: {
        success: true,
        message: 'Flight filter created successfully',
        filter: filter_to_json(result[:filter]),
        filter_id: result[:filter].id
      }, status: :created
    else
      render json: {
        success: false,
        message: 'Failed to create flight filter',
        errors: result[:errors]
      }, status: :unprocessable_entity
    end
  end

  def update
    service = FlightFilterService.new(@flight_filter)
    
    result = service.update_filter(@flight_filter.id, flight_filter_params)
    
    if result[:success]
      render json: {
        success: true,
        message: 'Flight filter updated successfully',
        filter: filter_to_json(result[:filter])
      }
    else
      render json: {
        success: false,
        message: 'Failed to update flight filter',
        errors: result[:errors]
      }, status: :unprocessable_entity
    end
  end

  def destroy
    if @flight_filter.destroy
      render json: {
        success: true,
        message: 'Flight filter deleted successfully'
      }
    else
      render json: {
        success: false,
        message: 'Failed to delete flight filter',
        errors: @flight_filter.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def duplicate
    original_filter = FlightFilter.find(params[:id])
    service = FlightFilterService.new
    
    # For testing, create a mock user or use a default user
    # In production: user = current_user
    user = User.first # Temporary for testing
    
    result = service.duplicate_filter(original_filter.id, user)
    
    if result[:success]
      render json: {
        success: true,
        message: 'Flight filter duplicated successfully',
        filter: filter_to_json(result[:filter])
      }
    else
      render json: {
        success: false,
        message: 'Failed to duplicate flight filter',
        errors: result[:errors]
      }, status: :unprocessable_entity
    end
  end

  def bulk_action
    filter_ids = params[:filter_ids]
    action = params[:bulk_action]
    
    if filter_ids.blank?
      render json: {
        success: false,
        message: 'No filters selected'
      }, status: :bad_request
      return
    end
    
    service = FlightFilterService.new
    operations = {}
    
    case action
    when 'activate'
      operations[:activate] = true
    when 'deactivate'
      operations[:deactivate] = true
    when 'delete'
      operations[:delete] = true
    else
      render json: {
        success: false,
        message: 'Invalid action'
      }, status: :bad_request
      return
    end
    
    result = service.bulk_operations(filter_ids, operations)
    
    render json: {
      success: true,
      message: "Bulk operation '#{action}' completed",
      results: result
    }
  end

  def validate_route
    origin_airports = params[:origin_airports]
    destination_airports = params[:destination_airports]
    trip_type = params[:trip_type]
    
    service = FlightFilterService.new
    is_valid = service.validate_route_combination(origin_airports, destination_airports, trip_type)
    
    render json: {
      success: true,
      is_valid: is_valid,
      errors: service.errors
    }
  end

  def check_duplicates
    filter_params = flight_filter_params
    
    # For testing, create a mock user or use a default user
    # In production: user_id = current_user.id
    user_id = User.first&.id # Temporary for testing
    
    service = FlightFilterService.new
    duplicates = service.detect_duplicate_filters(user_id, filter_params)
    
    render json: {
      success: true,
      has_duplicates: duplicates.any?,
      duplicate_count: duplicates.count,
      duplicates: duplicates.map { |filter| filter_to_json(filter) }
    }
  end

  def monitoring_schedule
    filter = FlightFilter.find(params[:id])
    service = FlightFilterService.new
    
    schedule = service.optimize_monitoring_schedule(filter)
    priority = service.calculate_monitoring_priority(filter)
    
    render json: {
      success: true,
      schedule: schedule,
      priority: priority,
      is_urgent: filter.is_urgent?,
      should_monitor_frequently: filter.should_monitor_frequently?
    }
  end

  private

  def set_flight_filter
    @flight_filter = FlightFilter.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: {
      success: false,
      message: 'Flight filter not found'
    }, status: :not_found
  end

  def flight_filter_params
    params.require(:flight_filter).permit(
      :name, :description, :trip_type, :flexible_dates, :date_flexibility,
      :origin_airports, :destination_airports, :departure_dates, :return_dates,
      passenger_details: [:adults, :children, :infants],
      price_parameters: [:target_price, :max_price, :min_price, :currency],
      advanced_preferences: [:cabin_class, :max_stops, :airline_preferences, :preferred_times],
      alert_settings: [:monitor_frequency, :notification_methods, :price_drop_threshold]
    )
  end

  def filter_to_json(filter, include_details: false)
    json = {
      id: filter.id,
      name: filter.name,
      description: filter.description,
      trip_type: filter.trip_type,
      route_description: filter.route_description,
      origin_airports: filter.origin_airports_array,
      destination_airports: filter.destination_airports_array,
      departure_dates: filter.departure_dates_array,
      return_dates: filter.return_dates_array,
      flexible_dates: filter.flexible_dates,
      date_flexibility: filter.date_flexibility,
      passenger_details: filter.passenger_details,
      passenger_count: filter.passenger_count,
      price_parameters: filter.price_parameters,
      advanced_preferences: filter.advanced_preferences,
      alert_settings: filter.alert_settings,
      is_active: filter.is_active,
      created_at: filter.created_at,
      updated_at: filter.updated_at
    }
    
    if include_details
      json[:flight_alerts] = filter.flight_alerts.map { |alert| alert_to_json(alert) }
      json[:price_history] = get_price_history_for_filter(filter)
      json[:monitoring_stats] = get_monitoring_stats_for_filter(filter)
    end
    
    json
  end

  def alert_to_json(alert)
    {
      id: alert.id,
      origin: alert.origin,
      destination: alert.destination,
      departure_date: alert.departure_date,
      return_date: alert.return_date,
      passengers: alert.passengers,
      cabin_class: alert.cabin_class,
      target_price: alert.target_price,
      current_price: alert.current_price,
      price_drop_percentage: alert.price_drop_percentage,
      status: alert.status,
      notification_method: alert.notification_method,
      alert_quality_score: alert.alert_quality_score,
      last_checked: alert.last_checked,
      next_check_scheduled: alert.next_check_scheduled,
      created_at: alert.created_at
    }
  end

  def get_price_history_for_filter(filter)
    route = filter.route_description
    
    FlightPriceHistory.by_route(route)
                     .recent
                     .order(:date)
                     .limit(30)
                     .map do |history|
      {
        date: history.date,
        price: history.price,
        provider: history.provider,
        booking_class: history.booking_class,
        data_quality_score: history.data_quality_score,
        price_validation_status: history.price_validation_status,
        timestamp: history.timestamp
      }
    end
  end

  def get_monitoring_stats_for_filter(filter)
    alerts = filter.flight_alerts
    
    {
      total_alerts: alerts.count,
      active_alerts: alerts.active.count,
      triggered_alerts: alerts.where(status: 'triggered').count,
      average_quality_score: alerts.average(:alert_quality_score)&.round(2) || 0,
      last_alert_triggered: alerts.where(status: 'triggered').maximum(:updated_at),
      monitoring_frequency: filter.monitor_frequency,
      is_urgent: filter.is_urgent?,
      should_monitor_frequently: filter.should_monitor_frequently?
    }
  end
end

# Placeholder controller for coming soon mode (production)
# class Api::FlightFiltersController < ApplicationController
#   def create
#     redirect_to root_path
#   end

#   def index
#     redirect_to root_path
#   end

#   def show
#     redirect_to root_path
#   end

#   def destroy
#     redirect_to root_path
#   end
# end
