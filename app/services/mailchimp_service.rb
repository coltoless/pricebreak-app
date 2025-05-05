class MailchimpService
  def initialize
    @gibbon = Gibbon::Request.new(api_key: ENV['MAILCHIMP_API_KEY'])
    @list_id = ENV['MAILCHIMP_LIST_ID']
  end

  def subscribe(email)
    begin
      @gibbon.lists(@list_id).members.create(
        body: {
          email_address: email,
          status: 'subscribed',
          tags: ['launch_subscriber']
        }
      )
      true
    rescue Gibbon::MailChimpError => e
      Rails.logger.error "Mailchimp subscription failed: #{e.message}"
      false
    end
  end

  def unsubscribe(email)
    begin
      subscriber_hash = Digest::MD5.hexdigest(email.downcase)
      @gibbon.lists(@list_id).members(subscriber_hash).update(
        body: { status: 'unsubscribed' }
      )
      true
    rescue Gibbon::MailChimpError => e
      Rails.logger.error "Mailchimp unsubscription failed: #{e.message}"
      false
    end
  end
end 