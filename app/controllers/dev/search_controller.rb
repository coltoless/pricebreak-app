module Dev
  class SearchController < ApplicationController
    layout 'dev'

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

      # Sample data for development
      @results = [
        {
          id: 1,
          name: "Taylor Swift - The Eras Tour",
          venue: "Madison Square Garden",
          date: Time.current + 1.week,
          price: 299.99,
          category: "concerts",
          subcategory: "pop",
          image_url: "https://via.placeholder.com/300x200",
          ticket_url: "https://www.ticketmaster.com/taylor-swift-tickets/artist/1940065",
          source: "Ticketmaster"
        },
        {
          id: 2,
          name: "New York Knicks vs. Boston Celtics",
          venue: "TD Garden",
          date: Time.current + 2.days,
          price: 89.99,
          category: "sports",
          subcategory: "basketball",
          image_url: "https://via.placeholder.com/300x200",
          ticket_url: "https://www.stubhub.com/new-york-knicks-boston-celtics-tickets/group/1032024/",
          source: "StubHub"
        },
        {
          id: 3,
          name: "Dave Chappelle Live",
          venue: "Comedy Cellar",
          date: Time.current + 3.days,
          price: 49.99,
          category: "comedy",
          subcategory: "standup",
          image_url: "https://via.placeholder.com/300x200",
          ticket_url: "https://www.vividseats.com/comedy/dave-chappelle-tickets.html",
          source: "Vivid Seats"
        }
      ]

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

    def results
      # This endpoint is for testing the results partial in isolation
      @results = [
        {
          id: 1,
          name: "Sample Event",
          venue: "Sample Venue",
          date: Time.current,
          price: 99.99,
          category: "concerts",
          subcategory: "rock",
          image_url: "https://via.placeholder.com/300x200",
          ticket_url: "https://www.ticketmaster.com/",
          source: "Sample Source"
        }
      ]

      render partial: 'results', locals: { results: @results }
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
      # In development, we'll just log the alert creation
      Rails.logger.info "Price Alert created: #{search_params.to_h}"
    end
  end
end 