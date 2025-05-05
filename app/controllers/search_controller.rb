class SearchController < ApplicationController
  def index
    @query = params[:q]
    @category = params[:category]
    @venue_type = params[:venue_type]
    @artist = params[:artist]
    @team = params[:team]
    @from = params[:from]
    @to = params[:to]
    @price_min = params[:price_min]
    @price_max = params[:price_max]
    @price_range = params[:price_preset]
    @date_range = params[:date_preset]
    @start_date = params[:start_date]
    @end_date = params[:end_date]
    @sort_by = params[:sort_by] || 'best_match'
    @enable_notifications = params[:enable_notifications]
    @target_price = params[:target_price]
    @notification_method = params[:notification_method]

    @results = TicketApis::AggregatorService.search(
      query: @query,
      category: @category,
      venue_type: @venue_type,
      artist: @artist,
      team: @team,
      from: @from,
      to: @to,
      price_min: @price_min,
      price_max: @price_max,
      date_range: @date_range,
      start_date: @start_date,
      end_date: @end_date,
      sort_by: @sort_by
    )

    if @enable_notifications && @target_price.present?
      create_price_alert
    end

    respond_to do |format|
      format.html
      format.json do
        render json: {
          html: render_to_string(partial: 'results', locals: { results: @results }, formats: [:html])
        }
      end
    end
  end

  private

  def search_params
    params.permit(
      :q,
      :artist,
      :team,
      :from,
      :to,
      :price_min,
      :price_max,
      :price_preset,
      :date_preset,
      :start_date,
      :end_date,
      :sort_by,
      :enable_notifications,
      :target_price,
      :notification_method,
      category: [],
      venue_type: []
    )
  end

  def create_price_alert
    PriceAlert.create!(
      user: current_user,
      query: @query,
      category: @category,
      venue_type: @venue_type,
      artist: @artist,
      team: @team,
      from: @from,
      to: @to,
      price_min: @price_min,
      price_max: @price_max,
      target_price: @target_price,
      notification_method: @notification_method,
      status: 'active'
    )
  end
end 