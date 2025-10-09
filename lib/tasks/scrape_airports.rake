# Airport Data Scraper Task
# This task scrapes comprehensive airport data from multiple sources

namespace :airports do
  desc "Scrape comprehensive airport data from web sources"
  task scrape: :environment do
    puts "🌍 Starting comprehensive airport data scraping..."
    
    begin
      require 'net/http'
      require 'json'
      require 'csv'
      require 'uri'
      
      # Scrape from multiple sources
      airports = []
      
      puts "📥 Scraping from OurAirports..."
      airports.concat(scrape_ourairports)
      
      puts "📥 Scraping from OpenFlights..."
      airports.concat(scrape_openflights)
      
      puts "📥 Scraping from Aviation Edge..."
      airports.concat(scrape_aviation_edge)
      
      # Remove duplicates and clean data
      puts "🧹 Cleaning and deduplicating data..."
      cleaned_airports = clean_and_deduplicate_airports(airports)
      
      puts "💾 Saving to local database..."
      save_airports_to_local(cleaned_airports)
      
      puts "✅ Airport scraping completed successfully!"
      puts "📊 Total airports processed: #{airports.length}"
      puts "📊 Unique airports saved: #{cleaned_airports.length}"
      
    rescue => e
      puts "❌ Error during airport scraping: #{e.message}"
      puts e.backtrace.first(5).join("\n")
      exit 1
    end
  end
  
  desc "Update local airport database file"
  task update_local: :environment do
    puts "🔄 Updating local airport database..."
    
    begin
      # Read from our scraped data
      airports_data = JSON.parse(File.read(Rails.root.join('tmp', 'scraped_airports.json')))
      
      # Generate TypeScript file
      generate_typescript_database(airports_data)
      
      puts "✅ Local airport database updated!"
      
    rescue => e
      puts "❌ Error updating local database: #{e.message}"
      exit 1
    end
  end
  
  private
  
  def scrape_ourairports
    puts "  📡 Fetching from OurAirports CSV..."
    
    begin
      uri = URI('https://raw.githubusercontent.com/davidmegginson/ourairports-data/main/airports.csv')
      response = Net::HTTP.get_response(uri)
      
      if response.code != '200'
        puts "  ⚠️ Failed to fetch OurAirports data: HTTP #{response.code}"
        return []
      end
      
      csv_data = CSV.parse(response.body, headers: true)
      airports = []
      
      csv_data.each do |row|
        # Only include airports with IATA codes and active status
        next unless row['iata_code'].present? && row['iata_code'] != 'null'
        next unless ['airport', 'large_airport', 'medium_airport'].include?(row['type'])
        
        airport = {
          iata_code: row['iata_code'].upcase,
          icao_code: row['ident'].upcase,
          name: clean_airport_name(row['name']),
          city: row['municipality'] || row['name'],
          country: row['iso_country'],
          latitude: row['latitude_deg'].to_f,
          longitude: row['longitude_deg'].to_f,
          altitude: row['elevation_ft'].to_i,
          timezone: row['tz'],
          source: 'ourairports',
          created_at: Time.current
        }
        
        airports << airport
      end
      
      puts "  ✅ Scraped #{airports.length} airports from OurAirports"
      airports
      
    rescue => e
      puts "  ❌ Error scraping OurAirports: #{e.message}"
      []
    end
  end
  
  def scrape_openflights
    puts "  📡 Fetching from OpenFlights..."
    
    begin
      uri = URI('https://raw.githubusercontent.com/jpatokal/openflights/master/data/airports.dat')
      response = Net::HTTP.get_response(uri)
      
      if response.code != '200'
        puts "  ⚠️ Failed to fetch OpenFlights data: HTTP #{response.code}"
        return []
      end
      
      airports = []
      response.body.each_line do |line|
        # OpenFlights format: ID, Name, City, Country, IATA, ICAO, Latitude, Longitude, Altitude, Timezone, DST, Tz, Type, Source
        fields = line.split(',')
        next if fields.length < 14
        
        iata_code = fields[4].gsub('"', '').strip
        next if iata_code.empty? || iata_code == '\\N'
        
        airport = {
          iata_code: iata_code.upcase,
          icao_code: fields[5].gsub('"', '').strip.upcase,
          name: clean_airport_name(fields[1].gsub('"', '')),
          city: fields[2].gsub('"', ''),
          country: fields[3].gsub('"', ''),
          latitude: fields[6].to_f,
          longitude: fields[7].to_f,
          altitude: fields[8].to_i,
          timezone: fields[11].gsub('"', ''),
          source: 'openflights',
          created_at: Time.current
        }
        
        airports << airport
      end
      
      puts "  ✅ Scraped #{airports.length} airports from OpenFlights"
      airports
      
    rescue => e
      puts "  ❌ Error scraping OpenFlights: #{e.message}"
      []
    end
  end
  
  def scrape_aviation_edge
    puts "  📡 Fetching from Aviation Edge (mock data)..."
    
    # Since Aviation Edge requires API key, we'll create comprehensive mock data
    # for major airports that might be missing
    additional_airports = [
      # Major African airports
      { iata_code: 'CAI', name: 'Cairo International Airport', city: 'Cairo', country: 'Egypt', icao_code: 'HECA' },
      { iata_code: 'JNB', name: 'O.R. Tambo International Airport', city: 'Johannesburg', country: 'South Africa', icao_code: 'FAOR' },
      { iata_code: 'LAD', name: 'Quatro de Fevereiro Airport', city: 'Luanda', country: 'Angola', icao_code: 'FNLU' },
      { iata_code: 'LOS', name: 'Murtala Muhammed International Airport', city: 'Lagos', country: 'Nigeria', icao_code: 'DNMM' },
      { iata_code: 'NBO', name: 'Jomo Kenyatta International Airport', city: 'Nairobi', country: 'Kenya', icao_code: 'HKJK' },
      
      # Major South American airports
      { iata_code: 'GRU', name: 'São Paulo/Guarulhos International Airport', city: 'São Paulo', country: 'Brazil', icao_code: 'SBGR' },
      { iata_code: 'EZE', name: 'Ministro Pistarini International Airport', city: 'Buenos Aires', country: 'Argentina', icao_code: 'SAEZ' },
      { iata_code: 'SCL', name: 'Arturo Merino Benítez International Airport', city: 'Santiago', country: 'Chile', icao_code: 'SCEL' },
      { iata_code: 'LIM', name: 'Jorge Chávez International Airport', city: 'Lima', country: 'Peru', icao_code: 'SPJC' },
      { iata_code: 'BOG', name: 'El Dorado International Airport', city: 'Bogotá', country: 'Colombia', icao_code: 'SKBO' },
      
      # Major Middle Eastern airports
      { iata_code: 'IST', name: 'Istanbul Airport', city: 'Istanbul', country: 'Turkey', icao_code: 'LTFM' },
      { iata_code: 'TLV', name: 'Ben Gurion Airport', city: 'Tel Aviv', country: 'Israel', icao_code: 'LLBG' },
      { iata_code: 'BAH', name: 'Bahrain International Airport', city: 'Manama', country: 'Bahrain', icao_code: 'OBBI' },
      { iata_code: 'KWI', name: 'Kuwait International Airport', city: 'Kuwait City', country: 'Kuwait', icao_code: 'OKBK' },
      { iata_code: 'MCT', name: 'Muscat International Airport', city: 'Muscat', country: 'Oman', icao_code: 'OOMS' },
      
      # Major Asian airports (additional)
      { iata_code: 'DEL', name: 'Indira Gandhi International Airport', city: 'New Delhi', country: 'India', icao_code: 'VIDP' },
      { iata_code: 'BOM', name: 'Chhatrapati Shivaji Maharaj International Airport', city: 'Mumbai', country: 'India', icao_code: 'VABB' },
      { iata_code: 'BLR', name: 'Kempegowda International Airport', city: 'Bangalore', country: 'India', icao_code: 'VOBL' },
      { iata_code: 'MAA', name: 'Chennai International Airport', city: 'Chennai', country: 'India', icao_code: 'VOMM' },
      { iata_code: 'CCU', name: 'Netaji Subhash Chandra Bose International Airport', city: 'Kolkata', country: 'India', icao_code: 'VECC' },
      
      # Major European airports (additional)
      { iata_code: 'MAD', name: 'Adolfo Suárez Madrid-Barajas Airport', city: 'Madrid', country: 'Spain', icao_code: 'LEMD' },
      { iata_code: 'BCN', name: 'Barcelona-El Prat Airport', city: 'Barcelona', country: 'Spain', icao_code: 'LEBL' },
      { iata_code: 'FCO', name: 'Leonardo da Vinci International Airport', city: 'Rome', country: 'Italy', icao_code: 'LIRF' },
      { iata_code: 'MXP', name: 'Milan Malpensa Airport', city: 'Milan', country: 'Italy', icao_code: 'LIMC' },
      { iata_code: 'ZUR', name: 'Zurich Airport', city: 'Zurich', country: 'Switzerland', icao_code: 'LSZH' },
      
      # Major North American airports (additional)
      { iata_code: 'YYZ', name: 'Toronto Pearson International Airport', city: 'Toronto', country: 'Canada', icao_code: 'CYYZ' },
      { iata_code: 'YVR', name: 'Vancouver International Airport', city: 'Vancouver', country: 'Canada', icao_code: 'CYVR' },
      { iata_code: 'YUL', name: 'Montréal-Pierre Elliott Trudeau International Airport', city: 'Montreal', country: 'Canada', icao_code: 'CYUL' },
      { iata_code: 'MEX', name: 'Mexico City International Airport', city: 'Mexico City', country: 'Mexico', icao_code: 'MMMX' },
      { iata_code: 'CUN', name: 'Cancún International Airport', city: 'Cancún', country: 'Mexico', icao_code: 'MMUN' },
      
      # Major Oceania airports (additional)
      { iata_code: 'MEL', name: 'Melbourne Airport', city: 'Melbourne', country: 'Australia', icao_code: 'YMML' },
      { iata_code: 'BNE', name: 'Brisbane Airport', city: 'Brisbane', country: 'Australia', icao_code: 'YBBN' },
      { iata_code: 'PER', name: 'Perth Airport', city: 'Perth', country: 'Australia', icao_code: 'YPPH' },
      { iata_code: 'AKL', name: 'Auckland Airport', city: 'Auckland', country: 'New Zealand', icao_code: 'NZAA' },
      { iata_code: 'WLG', name: 'Wellington Airport', city: 'Wellington', country: 'New Zealand', icao_code: 'NZWN' }
    ]
    
    airports = additional_airports.map do |airport_data|
      {
        iata_code: airport_data[:iata_code],
        icao_code: airport_data[:icao_code],
        name: airport_data[:name],
        city: airport_data[:city],
        country: airport_data[:country],
        latitude: 0.0, # Will be filled from other sources
        longitude: 0.0,
        altitude: 0,
        timezone: 'UTC',
        source: 'aviation_edge_mock',
        created_at: Time.current
      }
    end
    
    puts "  ✅ Added #{airports.length} additional major airports"
    airports
  end
  
  def clean_airport_name(name)
    # Clean up airport names
    name.gsub(/[^\w\s\-'\.]/, '').strip
  end
  
  def clean_and_deduplicate_airports(airports)
    puts "  🧹 Cleaning and deduplicating #{airports.length} airports..."
    
    # Group by IATA code and merge data
    grouped = airports.group_by { |a| a[:iata_code] }
    cleaned = []
    
    grouped.each do |iata_code, airport_group|
      # Take the airport with the most complete data
      best_airport = airport_group.max_by do |airport|
        completeness_score = 0
        completeness_score += 1 if airport[:name].present?
        completeness_score += 1 if airport[:city].present?
        completeness_score += 1 if airport[:country].present?
        completeness_score += 1 if airport[:latitude] != 0.0
        completeness_score += 1 if airport[:longitude] != 0.0
        completeness_score += 1 if airport[:icao_code].present?
        completeness_score
      end
      
      # Merge data from all sources
      merged_airport = {
        iata_code: iata_code,
        icao_code: best_airport[:icao_code],
        name: best_airport[:name],
        city: best_airport[:city],
        country: best_airport[:country],
        latitude: best_airport[:latitude],
        longitude: best_airport[:longitude],
        altitude: best_airport[:altitude],
        timezone: best_airport[:timezone],
        search_index: build_search_index(best_airport),
        sources: airport_group.map { |a| a[:source] }.uniq.join(','),
        created_at: Time.current,
        updated_at: Time.current
      }
      
      cleaned << merged_airport
    end
    
    # Sort by IATA code
    cleaned.sort_by { |a| a[:iata_code] }
  end
  
  def build_search_index(airport)
    # Create comprehensive search index
    search_terms = [
      airport[:iata_code],
      airport[:icao_code],
      airport[:name],
      airport[:city],
      airport[:country]
    ].compact.map(&:upcase).join(' ')
    
    search_terms
  end
  
  def save_airports_to_local(airports)
    # Save to JSON file for processing
    File.write(Rails.root.join('tmp', 'scraped_airports.json'), airports.to_json)
    
    # Also save to CSV for easy inspection
    CSV.open(Rails.root.join('tmp', 'scraped_airports.csv'), 'w') do |csv|
      csv << ['iata_code', 'icao_code', 'name', 'city', 'country', 'latitude', 'longitude', 'altitude', 'timezone', 'search_index', 'sources']
      airports.each do |airport|
        csv << [
          airport[:iata_code],
          airport[:icao_code],
          airport[:name],
          airport[:city],
          airport[:country],
          airport[:latitude],
          airport[:longitude],
          airport[:altitude],
          airport[:timezone],
          airport[:search_index],
          airport[:sources]
        ]
      end
    end
    
    puts "  💾 Saved #{airports.length} airports to tmp/scraped_airports.json and tmp/scraped_airports.csv"
  end
  
  def generate_typescript_database(airports_data)
    puts "  📝 Generating TypeScript database file..."
    
    ts_content = "// Comprehensive Airport Database\n"
    ts_content += "// Generated from web scraping on #{Time.current.strftime('%Y-%m-%d %H:%M:%S')}\n"
    ts_content += "// Total airports: #{airports_data.length}\n\n"
    ts_content += "import { Airport } from '../types/flight-filter';\n\n"
    ts_content += "export const airportDatabase: Airport[] = [\n"
    
    airports_data.each_with_index do |airport, index|
      ts_content += "  {\n"
      ts_content += "    iata_code: '#{airport['iata_code']}',\n"
      ts_content += "    name: '#{airport['name'].gsub("'", "\\'")}',\n"
      ts_content += "    city: '#{airport['city'].gsub("'", "\\'")}',\n"
      ts_content += "    country: '#{airport['country']}',\n"
      ts_content += "    search_index: '#{airport['search_index']}',\n"
      ts_content += "    icao_code: '#{airport['icao_code']}',\n"
      ts_content += "    latitude: #{airport['latitude']},\n"
      ts_content += "    longitude: #{airport['longitude']},\n"
      ts_content += "    altitude: #{airport['altitude']},\n"
      ts_content += "    timezone: '#{airport['timezone']}'\n"
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
        const popularCodes = ['ATL', 'LAX', 'ORD', 'DFW', 'DEN', 'JFK', 'SFO', 'SEA', 'LHR', 'CDG', 'FRA', 'AMS', 'NRT', 'ICN', 'PEK', 'PVG', 'HKG', 'SIN', 'DXB', 'SYD'];
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
    TS
    
    # Write to the TypeScript file
    File.write(Rails.root.join('app', 'javascript', 'lib', 'airportDatabase.ts'), ts_content)
    
    puts "  ✅ Generated TypeScript database with #{airports_data.length} airports"
  end
end


