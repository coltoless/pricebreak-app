# Commented out for coming soon mode (production)
# class FlightFiltersController < ApplicationController
#   def index
#     # This will render the view with the React component
#   end
# end

# ENABLED for local development
class FlightFiltersController < ApplicationController
  layout 'application'
  
  before_action :authenticate_user!
  before_action :set_flight_filter, only: [:show, :edit, :update, :destroy, :activate, :deactivate]
  before_action :ensure_user_owns_filter, only: [:show, :edit, :update, :destroy, :activate, :deactivate]

  def index
    @flight_filters = current_user.flight_filters.includes(:flight_alerts).order(created_at: :desc)
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
                                      .order(timestamp: :desc)
                                      .limit(30)
    
    # Get recent alerts
    @recent_alerts = @flight_filter.flight_alerts.order(created_at: :desc).limit(10)
    
    # Check if mock mode is active
    aggregator = FlightApis::AggregatorService.new
    @mock_mode = aggregator.mock_mode?
  end

  def new
    @flight_filter = FlightFilter.new
  end

  def create
    @flight_filter = current_user.flight_filters.build(flight_filter_params)
    
    respond_to do |format|
      if @flight_filter.save
        # Create associated flight alert
        begin
          create_flight_alert_for_filter(@flight_filter)
        rescue => e
          Rails.logger.error "Error creating flight alert: #{e.message}"
          # Continue even if alert creation fails
        end
        
        format.html { redirect_to @flight_filter, notice: 'Flight filter created successfully!' }
        format.json { render json: { success: true, id: @flight_filter.id, filter: @flight_filter }, status: :created }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: { success: false, errors: @flight_filter.errors.full_messages }, status: :unprocessable_entity }
      end
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

  def test_price_check
    @flight_filter = current_user.flight_filters.find(params[:id])
    
    begin
      # Use PriceMonitoringService to fetch real-time prices
      monitoring = PriceMonitoringService.new
      
      # Run monitoring (may take a moment)
      monitoring_result = nil
      begin
        monitoring.monitor_single_filter(@flight_filter)
        monitoring_result = { success: true, message: 'Price check completed' }
      rescue => e
        Rails.logger.error "Error in monitor_single_filter: #{e.message}"
        monitoring_result = { success: false, error: e.message }
      end
      
      # Get the latest price data (use route_description safely)
      route_desc = @flight_filter.route_description rescue nil
      latest_prices = if route_desc
        FlightPriceHistory.where(route: route_desc)
                         .order(timestamp: :desc)
                         .limit(10)
      else
        []
      end
      
      # Get alerts (use alert_status field)
      alerts = @flight_filter.flight_alerts.where(alert_status: 'triggered')
                             .order(created_at: :desc)
                             .limit(5)
      
      respond_to do |format|
        format.html { redirect_to @flight_filter, notice: 'Price check completed! Check the filter details page.' }
        format.json { 
          render json: {
            success: true,
            filter_id: @flight_filter.id,
            route: route_desc || 'N/A',
            monitoring_result: monitoring_result,
            latest_prices: latest_prices.map { |p| 
              { 
                price: p.price, 
                date: p.date&.to_s, 
                provider: p.provider, 
                timestamp: p.timestamp&.to_s 
              } 
            },
            alerts_triggered: alerts.count,
            alerts: alerts.map { |a| 
              { 
                id: a.id, 
                price: a.current_price, 
                target: a.target_price, 
                percentage_drop: a.price_drop_percentage 
              } 
            }
          }, status: :ok
        }
      end
    rescue ActiveRecord::RecordNotFound => e
      Rails.logger.error "Filter not found: #{e.message}"
      respond_to do |format|
        format.json { render json: { success: false, error: 'Filter not found' }, status: :not_found }
      end
    rescue => e
      Rails.logger.error "Error in test_price_check: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      respond_to do |format|
        format.json { render json: { success: false, error: e.message, backtrace: Rails.env.development? ? e.backtrace.first(5) : nil }, status: :internal_server_error }
      end
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
    unless @flight_filter.user_id == current_user.id
      redirect_to flight_filters_path, alert: 'You can only manage your own filters.'
    end
  end

  def flight_filter_params
    # Permit nested parameters properly - use strong parameters for nested hashes
    params.require(:flight_filter).permit(
      :name, :description, :trip_type, :flexible_dates, :date_flexibility,
      :origin_airports, :destination_airports, :departure_dates, :return_dates,
      :is_active,
      passenger_details: {},
      price_parameters: {},
      advanced_preferences: {},
      alert_settings: {}
    )
  end

  def create_flight_alert_for_filter(filter)
    # Create a flight alert based on the filter
    alert = filter.flight_alerts.build(
      user: current_user,
      origin: filter.origin_airports_array.first,
      destination: filter.destination_airports_array.first,
      departure_date: filter.departure_dates_array.first,
      return_date: filter.return_dates_array.first,
      passengers: filter.passenger_count,
      cabin_class: filter.cabin_class,
      target_price: filter.target_price,
      notification_method: 'email',
      alert_status: 'active'
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
