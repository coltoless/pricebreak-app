# Heroku Deployment Guide for Mailchimp Integration

## Quick Fix Checklist

Follow these steps to fix the survey form error and activate Mailchimp integration:

### Step 1: Set Mailchimp Environment Variables on Heroku

```bash
# Set your Mailchimp API Key
heroku config:set MAILCHIMP_API_KEY="your-api-key-here" --app pricebreak-app

# Set your Mailchimp List ID  
heroku config:set MAILCHIMP_LIST_ID="your-list-id-here" --app pricebreak-app
```

**Where to find these values:**
- API Key: Mailchimp → Account → Extras → API keys
- List ID: Mailchimp → Audience → Settings → Audience name and defaults → Audience ID

### Step 2: Deploy the Fixed Code

```bash
# Make sure you're in the project directory
cd /Users/katerynatymofeieva/pricebreak

# Deploy to Heroku
git push heroku main
```

If you don't have the heroku remote set up:
```bash
heroku git:remote -a pricebreak-app
git push heroku main
```

### Step 3: Run Database Migrations (if needed)

```bash
heroku run rails db:migrate --app pricebreak-app
```

### Step 4: Test the Connection

```bash
# Test Mailchimp connection
heroku run rails mailchimp:test_connection --app pricebreak-app
```

### Step 5: Test on Live Site

1. Visit: https://pricebreak-app.herokuapp.com
2. Enter your email in the form
3. Click "Notify Me"
4. You should see: "🎉 Thanks for signing up! We'll notify you when we launch."
5. Check Mailchimp to verify the email was added

### Step 6: Monitor Logs

```bash
# Watch live logs
heroku logs --tail --app pricebreak-app

# Filter for Mailchimp-related logs
heroku logs --tail --app pricebreak-app | grep -i mailchimp
```

## What Was Fixed

### 1. Async Processing
- Changed from synchronous to asynchronous Mailchimp syncing
- User gets instant feedback, Mailchimp processes in background
- Form submissions no longer block on Mailchimp API calls

### 2. Better Error Handling
- Added graceful fallbacks for Mailchimp failures
- Improved validation and error messages
- Better logging for debugging

### 3. Automatic Retries
- Mailchimp sync retries up to 5 times if it fails
- Uses exponential backoff for retries
- Handles "already subscribed" case gracefully

### 4. Environment Validation
- Service checks if credentials are configured before attempting sync
- Logs warnings if credentials are missing
- Doesn't crash if Mailchimp is not configured

## File Changes Made

1. **app/models/launch_subscriber.rb** - Changed to async callbacks
2. **app/services/mailchimp_service.rb** - Added validation & better error handling
3. **app/controllers/launch_subscribers_controller.rb** - Improved error handling
4. **app/jobs/mailchimp_sync_job.rb** - New background job for Mailchimp sync
5. **lib/tasks/mailchimp.rake** - New rake tasks for testing and management

## Testing Commands

### Test Mailchimp Connection
```bash
heroku run rails mailchimp:test_connection --app pricebreak-app
```

### Subscribe a Test Email
```bash
heroku run rails "mailchimp:test_subscribe[test@example.com]" --app pricebreak-app
```

### Check Subscriber Status
```bash
heroku run rails mailchimp:status --app pricebreak-app
```

### Sync All Existing Subscribers
```bash
heroku run rails mailchimp:sync_all --app pricebreak-app
```

## Troubleshooting

### Error: "Mailchimp credentials not configured"
**Fix:** Run Step 1 to set environment variables

### Error: Form shows generic error message
**Check logs:**
```bash
heroku logs --tail --app pricebreak-app
```

Look for specific error messages and refer to sections below.

### Error: "Member Exists"
This is normal - it means the email is already in Mailchimp. The service will update the existing subscriber.

### Error: "Invalid API Key"
- Double-check your API key in Mailchimp
- Make sure there are no extra spaces
- Re-run Step 1 with the correct key

### Error: "List Not Found"
- Verify your List ID in Mailchimp
- Make sure the list is active
- Re-run Step 1 with the correct List ID

### Emails Not Appearing in Mailchimp
1. Check if credentials are set: `heroku config --app pricebreak-app | grep MAILCHIMP`
2. Check logs for errors: `heroku logs --tail --app pricebreak-app | grep -i mailchimp`
3. Verify Sidekiq is running: `heroku ps --app pricebreak-app`
4. Check if jobs are queued: `heroku run rails runner "puts Sidekiq::Queue.new.size" --app pricebreak-app`

## Background Jobs

The app uses Sidekiq for background job processing. Make sure you have a worker dyno running:

```bash
# Check current dynos
heroku ps --app pricebreak-app

# If no worker is running, scale it up
heroku ps:scale worker=1 --app pricebreak-app
```

## Monitoring

### View Recent Subscribers
```bash
heroku run rails mailchimp:status --app pricebreak-app
```

### Check Background Job Queue
```bash
heroku run rails runner "puts Sidekiq::Queue.new.size" --app pricebreak-app
```

### View Failed Jobs
```bash
heroku run rails runner "puts Sidekiq::RetrySet.new.size" --app pricebreak-app
```

## Architecture Overview

```
User submits email
    ↓
LaunchSubscribersController
    ↓
LaunchSubscriber.save (immediate)
    ↓
Success message shown to user ✓
    ↓
after_create_commit callback
    ↓
MailchimpSyncJob.perform_later (queued)
    ↓
Sidekiq worker picks up job
    ↓
MailchimpService.subscribe
    ↓
Mailchimp API
```

## Success Criteria

✅ User can submit email without errors
✅ Success message appears immediately  
✅ Email is saved to database
✅ Email appears in Mailchimp list (within ~30 seconds)
✅ Duplicate submissions show friendly message
✅ Invalid emails show validation error
✅ Logs show successful Mailchimp sync

## Next Steps

Once everything is working:

1. Remove debug navigation from landing page (lines 98-102 in `app/views/home/index.html.erb`)
2. Set up Mailchimp welcome email automation
3. Monitor subscriber growth
4. Consider A/B testing the CTA copy
5. Add analytics tracking for form submissions

