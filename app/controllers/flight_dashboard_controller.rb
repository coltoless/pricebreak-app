class FlightDashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    @user = current_user
    
    # Get user's filters and alerts
    @flight_filters = @user.flight_filters.includes(:flight_alerts, :flight_price_histories)
                          .order(created_at: :desc)
                          .limit(10)
    
    @flight_alerts = @user.flight_alerts.includes(:flight_filter)
                         .order(created_at: :desc)
                         .limit(10)
    
    # Calculate statistics
    @filter_stats = {
      total: @user.flight_filters.count,
      active: @user.flight_filters.active.count,
      inactive: @user.flight_filters.inactive.count,
      triggered_alerts: @user.flight_alerts.where(status: 'triggered').count,
      total_savings: @user.total_savings,
      average_savings: @user.average_savings
    }
    
    @alert_stats = {
      total: @user.flight_alerts.count,
      active: @user.flight_alerts.where(status: 'active').count,
      triggered: @user.flight_alerts.where(status: 'triggered').count,
      paused: @user.flight_alerts.where(status: 'paused').count,
      expired: @user.flight_alerts.where(status: 'expired').count
    }
    
    # Get recent price history for dashboard charts
    @recent_price_history = FlightPriceHistory.joins("INNER JOIN flight_filters ON flight_price_histories.route = flight_filters.route_description")
                                               .where(flight_filters: { user_id: @user.id })
                                               .order(timestamp: :desc)
                                               .limit(50)
    
    # Get price trends
    @price_trends = calculate_price_trends
    
    respond_to do |format|
      format.html
      format.json { 
        render json: {
          filters: @flight_filters.map { |f| filter_to_json(f) },
          alerts: @flight_alerts.map { |a| alert_to_json(a) },
          stats: {
            filters: @filter_stats,
            alerts: @alert_stats
          },
          price_trends: @price_trends
        }
      }
    end
  end

  private

  def calculate_price_trends
    # Calculate price trends for user's active filters
    trends = {}
    
    @user.flight_filters.active.each do |filter|
      route = filter.route_description
      recent_prices = FlightPriceHistory.by_route(route)
                                      .where('timestamp >= ?', 30.days.ago)
                                      .order(:timestamp)
      
      if recent_prices.any?
        prices = recent_prices.pluck(:price)
        current_price = prices.last
        previous_price = prices[-7] || prices.first # Compare with 7 days ago or earliest
        
        trend = if current_price && previous_price
          if current_price < previous_price
            { direction: 'down', percentage: ((previous_price - current_price) / previous_price * 100).round(2) }
          elsif current_price > previous_price
            { direction: 'up', percentage: ((current_price - previous_price) / previous_price * 100).round(2) }
          else
            { direction: 'stable', percentage: 0 }
          end
        else
          { direction: 'unknown', percentage: 0 }
        end
        
        trends[route] = {
          current_price: current_price,
          trend: trend,
          data_points: prices.length
        }
      end
    end
    
    trends
  end

  def filter_to_json(filter)
    {
      id: filter.id,
      name: filter.name,
      description: filter.description,
      route: filter.route_description,
      trip_type: filter.trip_type,
      is_active: filter.is_active,
      created_at: filter.created_at,
      alerts_count: filter.flight_alerts.count,
      active_alerts_count: filter.flight_alerts.where(status: 'active').count
    }
  end

  def alert_to_json(alert)
    {
      id: alert.id,
      origin: alert.origin,
      destination: alert.destination,
      departure_date: alert.departure_date,
      current_price: alert.current_price,
      target_price: alert.target_price,
      status: alert.status,
      price_drop_percentage: alert.price_drop_percentage,
      created_at: alert.created_at,
      flight_filter_id: alert.flight_filter_id
    }
  end
end

