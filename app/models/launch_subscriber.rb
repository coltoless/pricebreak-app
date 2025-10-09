class LaunchSubscriber < ApplicationRecord
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  
  after_create_commit :sync_to_mailchimp_async
  after_destroy_commit :unsubscribe_from_mailchimp_async

  private

  def sync_to_mailchimp_async
    return if Rails.env.test?
    
    # Use a background job to avoid blocking the request
    MailchimpSyncJob.perform_later(email, 'subscribe')
  rescue => e
    Rails.logger.error "Failed to queue Mailchimp sync for #{email}: #{e.message}"
    # Don't fail the subscription if Mailchimp queuing fails
  end

  def unsubscribe_from_mailchimp_async
    return if Rails.env.test?
    
    MailchimpSyncJob.perform_later(email, 'unsubscribe')
  rescue => e
    Rails.logger.error "Failed to queue Mailchimp unsubscribe for #{email}: #{e.message}"
  end
end
