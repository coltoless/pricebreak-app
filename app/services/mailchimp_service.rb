class MailchimpService
  def initialize
    validate_credentials!
    @gibbon = Gibbon::Request.new(api_key: ENV['MAILCHIMP_API_KEY'])
    @list_id = ENV['MAILCHIMP_LIST_ID']
  end

  def subscribe(email)
    return false unless credentials_configured?
    
    begin
      @gibbon.lists(@list_id).members.create(
        body: {
          email_address: email,
          status: 'subscribed',
          tags: ['launch_subscriber']
        }
      )
      Rails.logger.info "Successfully subscribed #{email} to Mailchimp"
      true
    rescue Gibbon::MailChimpError => e
      # Handle already subscribed case
      if e.message.include?('Member Exists')
        Rails.logger.info "Email #{email} already exists in Mailchimp"
        update_existing_subscriber(email)
      else
        Rails.logger.error "Mailchimp subscription failed for #{email}: #{e.message}"
      end
      false
    rescue => e
      Rails.logger.error "Unexpected error subscribing #{email} to Mailchimp: #{e.message}"
      false
    end
  end

  def unsubscribe(email)
    return false unless credentials_configured?
    
    begin
      subscriber_hash = Digest::MD5.hexdigest(email.downcase)
      @gibbon.lists(@list_id).members(subscriber_hash).update(
        body: { status: 'unsubscribed' }
      )
      Rails.logger.info "Successfully unsubscribed #{email} from Mailchimp"
      true
    rescue Gibbon::MailChimpError => e
      Rails.logger.error "Mailchimp unsubscription failed for #{email}: #{e.message}"
      false
    rescue => e
      Rails.logger.error "Unexpected error unsubscribing #{email} from Mailchimp: #{e.message}"
      false
    end
  end

  private

  def credentials_configured?
    ENV['MAILCHIMP_API_KEY'].present? && ENV['MAILCHIMP_LIST_ID'].present?
  end

  def validate_credentials!
    unless credentials_configured?
      Rails.logger.warn "Mailchimp credentials not configured. Set MAILCHIMP_API_KEY and MAILCHIMP_LIST_ID environment variables."
    end
  end

  def update_existing_subscriber(email)
    # Update the existing subscriber instead of creating
    begin
      subscriber_hash = Digest::MD5.hexdigest(email.downcase)
      @gibbon.lists(@list_id).members(subscriber_hash).update(
        body: { 
          status: 'subscribed',
          tags: ['launch_subscriber']
        }
      )
      true
    rescue => e
      Rails.logger.error "Failed to update existing subscriber #{email}: #{e.message}"
      false
    end
  end
end 