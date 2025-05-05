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
  end
end 