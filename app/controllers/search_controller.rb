class SearchController < ApplicationController
  def index
    @origin = params[:origin]
    @destination = params[:destination]
    @departure_date = params[:departure_date]
    @return_date = params[:return_date]
    @passengers = params[:passengers] || 1
    @cabin_class = params[:cabin_class] || 'economy'
    @price_min = params[:price_min]
    @price_max = params[:price_max]
    @sort_by = params[:sort_by] || 'price'
    @enable_notifications = params[:enable_notifications]
    @target_price = params[:target_price]
    @notification_method = params[:notification_method]
    @wedding_mode = params[:wedding_mode] == 'true'
    @wedding_date = params[:wedding_date]
    @guest_count = params[:guest_count] || 1

    if @wedding_mode && @wedding_date.present?
      @results = FlightApis::AggregatorService.search_wedding_packages(
        Date.parse(@wedding_date),
        @destination,
        @guest_count
      )
    else
      @results = FlightApis::AggregatorService.search_all(
        origin: @origin,
        destination: @destination,
        departure_date: @departure_date,
        return_date: @return_date,
        passengers: @passengers,
        cabin_class: @cabin_class,
        price_min: @price_min,
        price_max: @price_max,
        sort_by: @sort_by
      )
    end

    # Temporarily disabled until migration is run
    # if @enable_notifications && @target_price.present?
    #   create_flight_alert
    # end

    respond_to do |format|
      format.html
      format.json do
        render json: {
          html: render_to_string(partial: 'results', locals: { results: @results }, formats: [:html])
        }
      end
    end
  end

  def airport_suggestions
    query = params[:q]
    suggestions = FlightApis::AggregatorService.get_airport_suggestions(query)
    
    render json: { suggestions: suggestions }
  end

  def price_history
    route = params[:route]
    date_range = params[:date_range]
    history = FlightApis::AggregatorService.get_price_history(route, date_range)
    
    render json: { history: history }
  end

  private

  def search_params
    params.permit(
      :origin,
      :destination,
      :departure_date,
      :return_date,
      :passengers,
      :cabin_class,
      :price_min,
      :price_max,
      :sort_by,
      :enable_notifications,
      :target_price,
      :notification_method,
      :wedding_mode,
      :wedding_date,
      :guest_count
    )
  end

  def create_flight_alert
    FlightAlert.create!(
      user: current_user,
      origin: @origin,
      destination: @destination,
      departure_date: @departure_date,
      return_date: @return_date,
      passengers: @passengers,
      cabin_class: @cabin_class,
      price_min: @price_min,
      price_max: @price_max,
      target_price: @target_price,
      notification_method: @notification_method,
      wedding_mode: @wedding_mode,
      wedding_date: @wedding_date,
      guest_count: @guest_count,
      status: 'active'
    )
  end
end 