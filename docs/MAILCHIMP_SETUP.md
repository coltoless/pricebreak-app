# Mailchimp Integration Setup

## Overview
This document explains how to set up and verify the Mailchimp integration for the PriceBreak landing page email subscription form.

## Prerequisites
1. A Mailchimp account
2. Access to your Heroku app

## Getting Your Mailchimp Credentials

### 1. Get Your API Key
1. Log into your Mailchimp account
2. Go to **Account** → **Extras** → **API keys**
3. Create a new API key or copy an existing one
4. Save this key - it will look like: `abc123def456ghi789-us21`

### 2. Get Your List ID
1. In Mailchimp, go to **Audience** → **All contacts**
2. Click on **Settings** → **Audience name and defaults**
3. Find the **Audience ID** (also called List ID)
4. It will look like: `a1b2c3d4e5`

## Setting Up on Heroku

### Set Environment Variables

Run these commands in your terminal (replace with your actual values):

```bash
heroku config:set MAILCHIMP_API_KEY="your-api-key-here" --app pricebreak-app
heroku config:set MAILCHIMP_LIST_ID="your-list-id-here" --app pricebreak-app
```

### Verify the Configuration

Check that the variables are set:

```bash
heroku config --app pricebreak-app | grep MAILCHIMP
```

You should see:
```
MAILCHIMP_API_KEY: abc123...
MAILCHIMP_LIST_ID: a1b2c3d4e5
```

## Testing the Integration

### Test on Production
1. Go to your live Heroku site: https://pricebreak-app.herokuapp.com
2. Enter an email in the subscription form
3. Click "Notify Me"
4. You should see a success message
5. Check your Mailchimp audience - the email should appear there

### Check Logs
If something goes wrong, check the Heroku logs:

```bash
heroku logs --tail --app pricebreak-app | grep -i mailchimp
```

## How It Works

1. User submits email on landing page
2. Email is saved to database immediately (fast response)
3. Background job queues Mailchimp sync
4. Mailchimp receives the subscription asynchronously
5. If Mailchimp fails, it retries automatically (up to 5 times)

## Common Issues

### Issue: "Mailchimp credentials not configured"
**Solution**: Set the MAILCHIMP_API_KEY and MAILCHIMP_LIST_ID environment variables

### Issue: "Member Exists" error
**Solution**: This is normal - the service automatically updates existing subscribers

### Issue: Email not appearing in Mailchimp
**Solution**: 
1. Check Heroku logs for errors
2. Verify API key is correct
3. Verify List ID is correct
4. Check Mailchimp for any API restrictions

## Architecture

- **LaunchSubscriber Model**: Handles email validation and database storage
- **LaunchSubscribersController**: Processes form submissions
- **MailchimpSyncJob**: Background job for async Mailchimp sync
- **MailchimpService**: Handles Mailchimp API communication

## Benefits of Async Design

- Fast user experience (no waiting for Mailchimp API)
- Automatic retries if Mailchimp is temporarily down
- User subscription saved even if Mailchimp fails
- No blocking of web requests

