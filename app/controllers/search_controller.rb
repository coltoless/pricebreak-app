class SearchController < ApplicationController
  def index
    @categories = {
      'Concerts' => ['Rock', 'Pop', 'Hip-Hop', 'Country', 'Jazz', 'Classical', 'Electronic', 'R&B', 'Metal', 'Folk'],
      'Sports' => ['Baseball', 'Basketball', 'Football', 'Hockey', 'Soccer', 'Tennis', 'Golf', 'Boxing', 'MMA', 'Racing'],
      'Comedy' => ['Stand-up', 'Improv', 'Sketch', 'Satire', 'Family-friendly'],
      'Flights' => ['Domestic', 'International', 'First Class', 'Business', 'Economy']
    }

    @price_ranges = [
      'Under $25',
      '$25 - $50',
      '$50 - $100',
      '$100 - $200',
      '$200+'
    ]

    @date_ranges = [
      'Today',
      'Tomorrow',
      'This Week',
      'This Weekend',
      'Next Week',
      'Next Month',
      'Custom Range'
    ]

    @venues = [
      'All Venues',
      'Stadiums',
      'Arenas',
      'Theaters',
      'Clubs',
      'Outdoor Venues'
    ]

    @sort_options = [
      'Best Match',
      'Price: Low to High',
      'Price: High to Low',
      'Date: Soonest First',
      'Date: Latest First',
      'Most Popular'
    ]

    # Fetch events based on search parameters
    @events = fetch_events
    @total_events = @events.size
  end

  private

  def fetch_events
    params = {
      q: params[:q],
      category: params[:category]&.first,
      start_date: parse_date_range(params[:date_range])&.first,
      end_date: parse_date_range(params[:date_range])&.last,
      price_min: parse_price_range(params[:price_range])&.first,
      price_max: parse_price_range(params[:price_range])&.last
    }

    EventService.fetch_events(params)
  end

  def parse_date_range(range)
    return nil unless range

    case range
    when 'Today'
      [Time.current.beginning_of_day, Time.current.end_of_day]
    when 'Tomorrow'
      [1.day.from_now.beginning_of_day, 1.day.from_now.end_of_day]
    when 'This Week'
      [Time.current.beginning_of_week, Time.current.end_of_week]
    when 'This Weekend'
      [Time.current.beginning_of_week + 5.days, Time.current.end_of_week]
    when 'Next Week'
      [1.week.from_now.beginning_of_week, 1.week.from_now.end_of_week]
    when 'Next Month'
      [1.month.from_now.beginning_of_month, 1.month.from_now.end_of_month]
    when 'Custom Range'
      [params[:start_date], params[:end_date]]
    end
  end

  def parse_price_range(range)
    return nil unless range

    case range
    when 'Under $25'
      [0, 25]
    when '$25 - $50'
      [25, 50]
    when '$50 - $100'
      [50, 100]
    when '$100 - $200'
      [100, 200]
    when '$200+'
      [200, nil]
    end
  end
end 