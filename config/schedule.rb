# Use this file to easily define all of your cron jobs.
# Learn more: http://github.com/javan/whenever

# Set the environment
set :environment, Rails.env

# Set the output log
set :output, "log/cron.log"

# Run quality updates every 6 hours
every 6.hours do
  runner "ScheduledQualityUpdateJob.perform_later"
end

# Run quality updates for high-priority alerts every hour
every 1.hour do
  runner "AlertQualityUpdateJob.schedule_quality_updates"
end

# Send weekly digest emails every Monday at 9 AM
every 1.week, at: '9:00 am' do
  runner "WeeklyDigestJob.perform_later"
end

# Clean up old data every day at 2 AM
every 1.day, at: '2:00 am' do
  runner "FlightDataCleanupJob.perform_later(:full)"
end

# Run trend analysis every 4 hours
every 4.hours do
  runner "PriceTrendAnalysisJob.perform_later(:full)"
end
