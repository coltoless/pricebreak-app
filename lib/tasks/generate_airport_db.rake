# Generate comprehensive airport database from scraped data
namespace :airports do
  desc "Generate TypeScript airport database from scraped data"
  task generate_db: :environment do
    puts "🔄 Generating comprehensive airport database..."
    
    begin
      # Read scraped data
      json_file = Rails.root.join('tmp', 'scraped_airports.json')
      unless File.exist?(json_file)
        puts "❌ No scraped data found. Run 'rails airports:scrape' first."
        exit 1
      end
      
      airports_data = JSON.parse(File.read(json_file))
      puts "📊 Processing #{airports_data.length} airports..."
      
      # Filter and clean data
      filtered_airports = airports_data.select do |airport|
        # Only include airports with valid IATA codes
        airport['iata_code'].present? && 
        airport['iata_code'].length == 3 && 
        airport['iata_code'] != 'null' &&
        airport['name'].present? &&
        airport['city'].present? &&
        airport['country'].present?
      end
      
      puts "📊 Filtered to #{filtered_airports.length} valid airports"
      
      # Generate TypeScript file
      generate_typescript_database(filtered_airports)
      
      puts "✅ Airport database generated successfully!"
      puts "📁 File: app/javascript/lib/airportDatabase.ts"
      puts "📊 Total airports: #{filtered_airports.length}"
      
    rescue => e
      puts "❌ Error generating database: #{e.message}"
      puts e.backtrace.first(5).join("\n")
      exit 1
    end
  end
  
  private
  
  def generate_typescript_database(airports_data)
    puts "  📝 Generating TypeScript database file..."
    
    ts_content = "// Comprehensive Airport Database\n"
    ts_content += "// Generated from web scraping on #{Time.current.strftime('%Y-%m-%d %H:%M:%S')}\n"
    ts_content += "// Total airports: #{airports_data.length}\n\n"
    ts_content += "import { Airport } from '../types/flight-filter';\n\n"
    ts_content += "export const airportDatabase: Airport[] = [\n"
    
    airports_data.each_with_index do |airport, index|
      # Clean and escape strings
      iata_code = airport['iata_code'].to_s.upcase.strip
      name = clean_string(airport['name'].to_s)
      city = clean_string(airport['city'].to_s)
      country = clean_string(airport['country'].to_s)
      icao_code = airport['icao_code'].to_s.upcase.strip
      search_index = build_search_index(iata_code, name, city, country, icao_code)
      
      ts_content += "  {\n"
      ts_content += "    iata_code: '#{iata_code}',\n"
      ts_content += "    name: '#{name}',\n"
      ts_content += "    city: '#{city}',\n"
      ts_content += "    country: '#{country}',\n"
      ts_content += "    search_index: '#{search_index}',\n"
      ts_content += "    icao_code: '#{icao_code}',\n"
      ts_content += "    latitude: #{airport['latitude'] || 0.0},\n"
      ts_content += "    longitude: #{airport['longitude'] || 0.0},\n"
      ts_content += "    altitude: #{airport['altitude'] || 0},\n"
      ts_content += "    timezone: '#{airport['timezone'] || 'UTC'}'\n"
      ts_content += "  }#{index < airports_data.length - 1 ? ',' : ''}\n"
    end
    
    ts_content += "];\n\n"
    
    # Add search functions
    ts_content += <<~TS
      // Enhanced search function with multiple field matching
      export function searchAirportsDatabase(searchTerm: string): Airport[] {
        if (!searchTerm || searchTerm.trim().length < 2) {
          return [];
        }

        const query = searchTerm.trim().toUpperCase();
        
        // Score airports based on match quality
        const scoredAirports = airportDatabase.map(airport => {
          let score = 0;
          
          // Exact IATA code match gets highest score
          if (airport.iata_code === query) {
            score += 1000;
          }
          
          // IATA code starts with query
          if (airport.iata_code.startsWith(query)) {
            score += 500;
          }
          
          // IATA code contains query
          if (airport.iata_code.includes(query)) {
            score += 200;
          }
          
          // Airport name starts with query
          if (airport.name.toUpperCase().startsWith(query)) {
            score += 300;
          }
          
          // Airport name contains query
          if (airport.name.toUpperCase().includes(query)) {
            score += 150;
          }
          
          // City starts with query
          if (airport.city.toUpperCase().startsWith(query)) {
            score += 250;
          }
          
          // City contains query
          if (airport.city.toUpperCase().includes(query)) {
            score += 100;
          }
          
          // Country starts with query
          if (airport.country.toUpperCase().startsWith(query)) {
            score += 200;
          }
          
          // Country contains query
          if (airport.country.toUpperCase().includes(query)) {
            score += 50;
          }
          
          // Search index contains query
          if (airport.search_index?.includes(query)) {
            score += 75;
          }
          
          return { airport, score };
        }).filter(item => item.score > 0);
        
        // Sort by score (highest first) and return top 15 results
        return scoredAirports
          .sort((a, b) => b.score - a.score)
          .slice(0, 15)
          .map(item => item.airport);
      }

      // Get airport by IATA code
      export function getAirportByIataCode(iataCode: string): Airport | null {
        const code = iataCode.trim().toUpperCase();
        return airportDatabase.find(airport => airport.iata_code === code) || null;
      }

      // Get popular airports (major hubs)
      export function getPopularAirports(): Airport[] {
        const popularCodes = [
          'ATL', 'LAX', 'ORD', 'DFW', 'DEN', 'JFK', 'SFO', 'SEA', 'LHR', 'CDG', 
          'FRA', 'AMS', 'NRT', 'ICN', 'PEK', 'PVG', 'HKG', 'SIN', 'DXB', 'SYD',
          'MAD', 'BCN', 'FCO', 'MXP', 'ZUR', 'YYZ', 'YVR', 'YUL', 'MEX', 'CUN',
          'MEL', 'BNE', 'PER', 'AKL', 'WLG', 'CAI', 'JNB', 'LOS', 'NBO', 'GRU',
          'EZE', 'SCL', 'LIM', 'BOG', 'IST', 'TLV', 'BAH', 'KWI', 'MCT', 'DEL',
          'BOM', 'BLR', 'MAA', 'CCU'
        ];
        return popularCodes
          .map(code => getAirportByIataCode(code))
          .filter((airport): airport is Airport => airport !== null);
      }

      // Get airports by country
      export function getAirportsByCountry(country: string): Airport[] {
        const countryUpper = country.trim().toUpperCase();
        return airportDatabase.filter(airport => 
          airport.country.toUpperCase().includes(countryUpper)
        );
      }

      // Get airports by region (simplified)
      export function getAirportsByRegion(region: string): Airport[] {
        const regionLower = region.trim().toLowerCase();
        
        const regionMap: { [key: string]: string[] } = {
          'north america': ['USA', 'Canada', 'Mexico'],
          'europe': ['UK', 'France', 'Germany', 'Netherlands', 'Spain', 'Italy', 'Switzerland', 'Austria', 'Belgium', 'Turkey'],
          'asia': ['Japan', 'South Korea', 'China', 'Hong Kong', 'Singapore', 'Thailand', 'Malaysia', 'Indonesia', 'India'],
          'middle east': ['UAE', 'Qatar', 'Saudi Arabia', 'Israel', 'Bahrain', 'Kuwait', 'Oman'],
          'africa': ['Egypt', 'South Africa', 'Angola', 'Nigeria', 'Kenya'],
          'oceania': ['Australia', 'New Zealand'],
          'south america': ['Brazil', 'Argentina', 'Chile', 'Peru', 'Colombia']
        };
        
        const countries = regionMap[regionLower] || [];
        return airportDatabase.filter(airport => 
          countries.some(country => airport.country.includes(country))
        );
      }

      // Get airport statistics
      export function getAirportStats(): { total: number, countries: number, regions: number } {
        const countries = new Set(airportDatabase.map(a => a.country));
        const regions = new Set(airportDatabase.map(a => {
          const country = a.country.toLowerCase();
          if (['usa', 'canada', 'mexico'].some(c => country.includes(c))) return 'North America';
          if (['uk', 'france', 'germany', 'netherlands', 'spain', 'italy', 'switzerland'].some(c => country.includes(c))) return 'Europe';
          if (['japan', 'china', 'singapore', 'india'].some(c => country.includes(c))) return 'Asia';
          if (['uae', 'qatar', 'israel'].some(c => country.includes(c))) return 'Middle East';
          if (['egypt', 'south africa', 'nigeria'].some(c => country.includes(c))) return 'Africa';
          if (['australia', 'new zealand'].some(c => country.includes(c))) return 'Oceania';
          if (['brazil', 'argentina', 'chile'].some(c => country.includes(c))) return 'South America';
          return 'Other';
        }));
        
        return {
          total: airportDatabase.length,
          countries: countries.size,
          regions: regions.size
        };
      }
    TS
    
    # Write to the TypeScript file
    File.write(Rails.root.join('app', 'javascript', 'lib', 'airportDatabase.ts'), ts_content)
    
    puts "  ✅ Generated TypeScript database with #{airports_data.length} airports"
  end
  
  def clean_string(str)
    # Clean and escape strings for TypeScript
    str.gsub("'", "\\'")
       .gsub('"', '\\"')
       .gsub("\n", ' ')
       .gsub("\r", ' ')
       .gsub(/[^\x20-\x7E]/, '') # Remove non-ASCII characters
       .gsub("'", '') # Remove any remaining apostrophes
       .strip
  end
  
  def build_search_index(iata_code, name, city, country, icao_code)
    # Create comprehensive search index
    search_terms = [iata_code, icao_code, name, city, country]
      .compact
      .map(&:upcase)
      .join(' ')
    
    search_terms
  end
end
