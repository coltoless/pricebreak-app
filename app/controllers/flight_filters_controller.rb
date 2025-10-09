# Commented out for coming soon mode (production)
# class FlightFiltersController < ApplicationController
#   def index
#     # This will render the view with the React component
#   end
# end

# ENABLED for local development
class FlightFiltersController < ApplicationController
  layout 'application'
  
  # Temporarily comment out for Phase 1 testing
  # before_action :authenticate_user!
  before_action :set_flight_filter, only: [:show, :edit, :update, :destroy, :activate, :deactivate]
  before_action :ensure_user_owns_filter, only: [:show, :edit, :update, :destroy, :activate, :deactivate]

  def index
    # For testing, create a mock user or use a default user
    @flight_filters = FlightFilter.all.includes(:flight_alerts).order(created_at: :desc)
    @active_filters = @flight_filters.active
    @inactive_filters = @flight_filters.inactive
    
    # Mock filter stats for testing
    @filter_stats = {
      total_filters: @flight_filters.count,
      active_filters: @active_filters.count,
      inactive_filters: @inactive_filters.count,
      triggered_alerts: 0,
      success_rate: 0.0
    }
  end

  def demo
    # Demo page for enhanced airport autocomplete system
    render :demo
  end

  def show
    @flight_filter = FlightFilter.includes(:flight_alerts, :flight_price_histories).find(params[:id])
    
    # Get price history for the route
    @price_history = FlightPriceHistory.by_route(@flight_filter.route_description)
                                      .recent
                                      .order(:date)
                                      .limit(30)
    
    # Get recent alerts
    @recent_alerts = @flight_filter.flight_alerts.order(created_at: :desc).limit(10)
  end

  def new
    @flight_filter = FlightFilter.new
  end

  def create
    @flight_filter = FlightFilter.new(flight_filter_params)
    
    if @flight_filter.save
      # Create associated flight alert
      create_flight_alert_for_filter(@flight_filter)
      
      redirect_to @flight_filter, notice: 'Flight filter created successfully!'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @flight_filter.update(flight_filter_params)
      redirect_to @flight_filter, notice: 'Flight filter updated successfully!'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @flight_filter.destroy
    redirect_to flight_filters_path, notice: 'Flight filter deleted successfully!'
  end

  def activate
    @flight_filter.activate!
    redirect_to @flight_filter, notice: 'Flight filter activated!'
  end

  def deactivate
    @flight_filter.deactivate!
    redirect_to @flight_filter, notice: 'Flight filter deactivated!'
  end

  def duplicate
    original_filter = FlightFilter.find(params[:id])
    @flight_filter = original_filter.dup
    
    # Modify the duplicate
    @flight_filter.name = "#{original_filter.name} (Copy)"
    @flight_filter.is_active = false
    
    if @flight_filter.save
      redirect_to @flight_filter, notice: 'Flight filter duplicated successfully!'
    else
      redirect_to original_filter, alert: 'Failed to duplicate filter.'
    end
  end

  def bulk_action
    filter_ids = params[:filter_ids]
    action = params[:bulk_action]
    
    if filter_ids.blank?
      redirect_to flight_filters_path, alert: 'No filters selected.'
      return
    end
    
    filters = FlightFilter.where(id: filter_ids)
    
    case action
    when 'activate'
      filters.update_all(is_active: true)
      message = 'Selected filters activated!'
    when 'deactivate'
      filters.update_all(is_active: false)
      message = 'Selected filters deactivated!'
    when 'delete'
      filters.destroy_all
      message = 'Selected filters deleted!'
    else
      redirect_to flight_filters_path, alert: 'Invalid action.'
      return
    end
    
    redirect_to flight_filters_path, notice: message
  end

  private

  def set_flight_filter
    @flight_filter = FlightFilter.find(params[:id])
  end

  def ensure_user_owns_filter
    # Temporarily disabled for testing
    # unless @flight_filter.user_id == current_user.id
    #   redirect_to flight_filters_path, alert: 'You can only manage your own filters.'
    # end
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

  def create_flight_alert_for_filter(filter)
    # Create a flight alert based on the filter
    alert = filter.flight_alerts.build(
      # user: current_user, # Temporarily disabled
      origin: filter.origin_airports_array.first,
      destination: filter.destination_airports_array.first,
      departure_date: filter.departure_dates_array.first,
      return_date: filter.return_dates_array.first,
      passengers: filter.passenger_count,
      cabin_class: filter.cabin_class,
      target_price: filter.target_price,
      notification_method: 'email',
      status: 'active'
    )
    
    alert.save!
  end
end

# Placeholder controller for coming soon mode (production)
# class FlightFiltersController < ApplicationController
#   def index
#     redirect_to root_path
#   end
# end
