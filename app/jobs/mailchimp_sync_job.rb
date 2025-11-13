class MailchimpSyncJob < ApplicationJob
  queue_as :default
  
  retry_on StandardError, wait: :exponentially_longer, attempts: 5

  def perform(email, action)
    return unless %w[subscribe unsubscribe].include?(action)
    
    mailchimp = MailchimpService.new
    
    case action
    when 'subscribe'
      result = mailchimp.subscribe(email)
      Rails.logger.info "Mailchimp sync job completed for #{email}: #{result ? 'success' : 'failed'}"
    when 'unsubscribe'
      result = mailchimp.unsubscribe(email)
      Rails.logger.info "Mailchimp unsubscribe job completed for #{email}: #{result ? 'success' : 'failed'}"
    end
  rescue => e
    Rails.logger.error "Mailchimp sync job failed for #{email} (#{action}): #{e.message}"
    raise # Let ActiveJob handle the retry logic
  end
end


