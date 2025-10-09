namespace :airports do
  desc "Upload airport data to Firebase Firestore"
  task upload: :environment do
    require 'csv'
    
    puts "Starting airport data upload to Firestore..."
    
    # Initialize Firebase Admin SDK
    begin
      # Check if Firebase is configured
      unless defined?(FirebaseAdmin)
        puts "Firebase Admin SDK not available. Please check your configuration."
        exit 1
      end
      
      firestore = FirebaseAdmin.firestore
      airports_collection = firestore.collection('airports')
      
      # Clear existing data (optional - comment out if you want to keep existing data)
      puts "Clearing existing airport data..."
      batch = firestore.batch
      existing_airports = airports_collection.get
      existing_airports.each do |doc|
        batch.delete(doc.ref)
      end
      batch.commit if existing_airports.any?
      
      # Process CSV file
      csv_file = Rails.root.join('airports.csv')
      unless File.exist?(csv_file)
        puts "Error: airports.csv not found. Please download it first."
        exit 1
      end
      
      uploaded_count = 0
      batch_count = 0
      batch = firestore.batch
      
      CSV.foreach(csv_file, headers: false) do |row|
        # OpenFlights CSV format:
        # 0: ID, 1: Name, 2: City, 3: Country, 4: IATA, 5: ICAO, 6: Latitude, 7: Longitude, 8: Altitude, 9: Timezone, 10: DST, 11: Tz database time zone, 12: Type, 13: Source
        
        next if row.length < 14
        
        iata_code = row[4]&.strip
        name = row[1]&.strip
        city = row[2]&.strip
        country = row[3]&.strip
        
        # Skip if no IATA code or if it's empty
        next if iata_code.blank? || iata_code == '\\N'
        
        # Create search index by combining code, name, and city (uppercase)
        search_parts = [iata_code, name, city].compact.reject(&:blank?)
        search_index = search_parts.join(' ').upcase
        
        # Create airport document
        airport_data = {
          iata_code: iata_code,
          name: name,
          city: city,
          country: country,
          search_index: search_index,
          icao_code: row[5]&.strip,
          latitude: row[6].to_f,
          longitude: row[7].to_f,
          altitude: row[8].to_i,
          timezone: row[11]&.strip,
          created_at: Time.current,
          updated_at: Time.current
        }
        
        # Add to batch
        doc_ref = airports_collection.doc(iata_code)
        batch.set(doc_ref, airport_data)
        uploaded_count += 1
        batch_count += 1
        
        # Commit batch every 500 documents (Firestore batch limit is 500)
        if batch_count >= 500
          batch.commit
          puts "Uploaded #{uploaded_count} airports..."
          batch = firestore.batch
          batch_count = 0
        end
        
        # Show progress every 1000 airports
        if uploaded_count % 1000 == 0
          puts "Processed #{uploaded_count} airports..."
        end
      end
      
      # Commit remaining documents
      if batch_count > 0
        batch.commit
      end
      
      puts "Successfully uploaded #{uploaded_count} airports to Firestore!"
      
    rescue => e
      puts "Error uploading airport data: #{e.message}"
      puts e.backtrace.first(5)
      exit 1
    end
  end
  
  desc "Test airport search functionality"
  task test_search: :environment do
    puts "Testing airport search functionality..."
    
    begin
      # Check if Firebase is configured
      unless defined?(FirebaseAdmin)
        puts "Firebase Admin SDK not available. Please check your configuration."
        exit 1
      end
      
      firestore = FirebaseAdmin.firestore
      airports_collection = firestore.collection('airports')
      
      # Test search for "JFK"
      puts "\nSearching for 'JFK'..."
      query = airports_collection.where('search_index', '>=', 'JFK').where('search_index', '<=', 'JFK' + "\uf8ff").limit(5)
      results = query.get
      
      results.each do |doc|
        data = doc.data
        puts "- #{data['iata_code']}: #{data['name']}, #{data['city']}, #{data['country']}"
      end
      
      # Test search for "NEW YORK"
      puts "\nSearching for 'NEW YORK'..."
      query = airports_collection.where('search_index', '>=', 'NEW YORK').where('search_index', '<=', 'NEW YORK' + "\uf8ff").limit(5)
      results = query.get
      
      results.each do |doc|
        data = doc.data
        puts "- #{data['iata_code']}: #{data['name']}, #{data['city']}, #{data['country']}"
      end
      
      puts "\nSearch test completed successfully!"
      
    rescue => e
      puts "Error testing search: #{e.message}"
      exit 1
    end
  end
end
