# Enable Firebase Authentication - Quick Guide

## ✅ What's Already Done

1. ✅ FirebaseUI implementation is complete
2. ✅ Project is linked to Firebase (`pricebreak-8cec7`)
3. ✅ Web app is created in Firebase
4. ✅ Environment variables are configured in `.env` file

## 🔧 What You Need to Do Now

### Step 1: Enable Authentication in Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **priceBreak** (`pricebreak-8cec7`)
3. Click on **Authentication** in the left sidebar
4. Click **Get started** (if you haven't enabled it yet)
5. Go to the **Sign-in method** tab
6. Enable the providers you want to use:

   **For Google:**
   - Click on **Google**
   - Toggle **Enable**
   - Add your support email
   - Click **Save**

   **For Email/Password:**
   - Click on **Email/Password**
   - Toggle **Enable** (first toggle)
   - Optionally enable **Email link (passwordless sign-in)**
   - Click **Save**

   **For other providers** (Facebook, Twitter, GitHub, etc.):
   - Click on the provider
   - Toggle **Enable**
   - Follow the setup instructions (you'll need API keys/secrets from those providers)
   - Click **Save**

### Step 2: Add Authorized Domains

1. In Firebase Console → **Authentication** → **Settings** tab
2. Scroll to **Authorized domains**
3. Make sure these domains are listed:
   - `localhost` (for development)
   - Your production domain (when you deploy)

### Step 3: Load Environment Variables

The `.env` file has been created with your Firebase configuration. Now you need to make sure Rails loads it.

**Option A: Use dotenv-rails (Recommended)**

Add to your `Gemfile`:
```ruby
gem 'dotenv-rails', groups: [:development, :test]
```

Then run:
```bash
bundle install
```

**Option B: Export variables manually**

```bash
export $(cat .env | xargs)
bin/rails server
```

**Option C: Use foreman or similar**

Create a `Procfile.dev`:
```
web: bin/rails server
```

Then run:
```bash
foreman start -f Procfile.dev
```

### Step 4: Restart Your Rails Server

After setting up environment variables, restart your server:

```bash
# Stop the current server
kill $(lsof -ti:3000)

# Start with environment variables loaded
# If using dotenv-rails:
bin/rails server

# Or export manually:
export $(cat .env | xargs) && bin/rails server
```

### Step 5: Test Firebase Authentication

1. Visit: http://localhost:3000/sign-in
2. You should see the FirebaseUI sign-in widget
3. Try signing in with one of the enabled providers
4. Check the browser console for any errors

## 🔍 Verify Configuration

### Check Environment Variables

```bash
# In your Rails console or terminal
rails runner "puts ENV['FIREBASE_API_KEY']"
```

Should output: `AIzaSyAFlWgRYiIyc05Er0de8Xmmy-LsqOnu4hs`

### Check Browser Console

Open http://localhost:3000 and check the browser console. You should see:
- ✅ `Firebase initialized successfully` (if configured correctly)
- ⚠️ `Firebase not configured` (if environment variables aren't loaded)

## 🐛 Troubleshooting

### "Firebase not configured" Warning

- **Check**: Are environment variables loaded?
  ```bash
  echo $FIREBASE_API_KEY
  ```
- **Solution**: Make sure `.env` file exists and Rails is loading it

### Authentication Providers Not Showing

- **Check**: Are providers enabled in Firebase Console?
- **Solution**: Go to Firebase Console → Authentication → Sign-in method and enable them

### "localhost not authorized" Error

- **Check**: Is `localhost` in authorized domains?
- **Solution**: Firebase Console → Authentication → Settings → Authorized domains

### Backend Authentication Fails

- **Check**: Is Firebase Admin SDK configured?
- **Solution**: Make sure Firebase service account credentials are in Rails credentials:
  ```bash
  rails credentials:edit
  ```
  Add under `firebase:` key (see `docs/FIREBASE_SETUP.md`)

## 📝 Current Configuration

- **Project ID**: `pricebreak-8cec7`
- **Web App ID**: `1:162273416649:web:e88da4aa0d9d4c78110418`
- **Auth Domain**: `pricebreak-8cec7.firebaseapp.com`
- **API Key**: `AIzaSyAFlWgRYiIyc05Er0de8Xmmy-LsqOnu4hs`

## 🎉 Next Steps

Once authentication is working:

1. Test all enabled sign-in providers
2. Verify backend integration (`/api/auth/login` endpoint)
3. Test user creation/update in your database
4. Customize the FirebaseUI appearance if needed
5. Set up production environment variables

## 📚 Additional Resources

- [FirebaseUI Documentation](https://firebase.google.com/docs/auth/web/firebaseui)
- [Firebase Authentication Setup](https://firebase.google.com/docs/auth/web/start)
- [FirebaseUI Setup Guide](./FIREBASEUI_SETUP.md)

