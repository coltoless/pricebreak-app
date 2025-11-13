namespace :mailchimp do
  desc "Check Mailchimp configuration and test connection"
  task test_connection: :environment do
    puts "\n=========================================="
    puts "Mailchimp Configuration Test"
    puts "==========================================\n"
    
    # Check environment variables
    api_key = ENV['MAILCHIMP_API_KEY']
    list_id = ENV['MAILCHIMP_LIST_ID']
    
    if api_key.blank?
      puts "❌ MAILCHIMP_API_KEY is not set"
    else
      puts "✅ MAILCHIMP_API_KEY is set (#{api_key[0..10]}...)"
    end
    
    if list_id.blank?
      puts "❌ MAILCHIMP_LIST_ID is not set"
    else
      puts "✅ MAILCHIMP_LIST_ID is set (#{list_id})"
    end
    
    if api_key.present? && list_id.present?
      puts "\nTesting connection to Mailchimp..."
      
      begin
        service = MailchimpService.new
        test_email = "test+#{Time.now.to_i}@example.com"
        
        puts "Attempting to subscribe test email: #{test_email}"
        result = service.subscribe(test_email)
        
        if result
          puts "✅ Successfully connected to Mailchimp!"
          puts "✅ Test email added to list"
          
          # Clean up test email
          puts "\nCleaning up test email..."
          service.unsubscribe(test_email)
          puts "✅ Test email removed"
        else
          puts "❌ Connection failed - check logs for details"
        end
      rescue => e
        puts "❌ Error testing connection: #{e.message}"
        puts e.backtrace.first(5).join("\n")
      end
    else
      puts "\n⚠️  Cannot test connection - credentials not configured"
      puts "\nTo set up Mailchimp:"
      puts "  heroku config:set MAILCHIMP_API_KEY=your-key --app pricebreak-app"
      puts "  heroku config:set MAILCHIMP_LIST_ID=your-list-id --app pricebreak-app"
    end
    
    puts "\n=========================================="
    puts "Test Complete"
    puts "==========================================\n"
  end
  
  desc "Subscribe a test email to Mailchimp"
  task :test_subscribe, [:email] => :environment do |t, args|
    email = args[:email] || "test@example.com"
    
    puts "Subscribing #{email} to Mailchimp..."
    service = MailchimpService.new
    result = service.subscribe(email)
    
    if result
      puts "✅ Successfully subscribed #{email}"
    else
      puts "❌ Failed to subscribe #{email} - check logs"
    end
  end
  
  desc "Sync all existing launch subscribers to Mailchimp"
  task sync_all: :environment do
    puts "Syncing all launch subscribers to Mailchimp..."
    
    count = 0
    errors = 0
    
    LaunchSubscriber.find_each do |subscriber|
      begin
        MailchimpSyncJob.perform_later(subscriber.email, 'subscribe')
        count += 1
        print "."
      rescue => e
        errors += 1
        puts "\n❌ Error queueing #{subscriber.email}: #{e.message}"
      end
    end
    
    puts "\n\n✅ Queued #{count} subscribers for sync"
    puts "❌ #{errors} errors" if errors > 0
  end
  
  desc "Show Mailchimp sync status"
  task status: :environment do
    total = LaunchSubscriber.count
    puts "\n=========================================="
    puts "Mailchimp Sync Status"
    puts "==========================================\n"
    puts "Total subscribers in database: #{total}"
    puts "\nRecent subscribers:"
    LaunchSubscriber.order(created_at: :desc).limit(10).each do |sub|
      puts "  - #{sub.email} (#{sub.created_at.strftime('%Y-%m-%d %H:%M')})"
    end
    puts "\n=========================================="
  end
end


