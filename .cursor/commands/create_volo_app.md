# Create Volo App

Use this command to generate a new full-stack application using the VoloBuilds create-volo-app starter kit.

## What You Get

**Full Stack:**
- ⚛️ React + TypeScript + Vite
- 🎨 Tailwind CSS + ShadCN components  
- 🔐 Firebase Authentication (Google Sign-In)
- 🔥 Hono API backend (NodeJS)
- 🗄️ Postgres database with Drizzle ORM

## Usage Examples

### Local Development (Default) - Working app in 30 seconds!
```
@create_volo_app.md

Create a new app called "my-todo-app" for local development
```

### Production Setup
```
@create_volo_app.md

Create a new app called "production-app" with full production services (--full flag)
```

### Specific Database
```
@create_volo_app.md

Create a new app called "neon-app" with Neon database integration
```

### Modular Setup
```
@create_volo_app.md

Create a new app called "hybrid-app" with production Firebase Auth but local database
```

## Available Flags

- `--full` - Full production setup
- `--auth` - Production Firebase + local database
- `--database neon|supabase` - Production database + local auth
- `--deploy` - Deployment setup + local services
- `--fast` - Minimal prompts for quick setup

## Requirements

- Node.js 20+
- pnpm

## What Happens

1. Runs `npx create-volo-app [app-name] [flags]`
2. Creates a new directory with your app
3. Sets up all the necessary files and dependencies
4. Provides local development environment with:
   - Embedded PostgreSQL database
   - Firebase Auth emulator
   - Frontend at `http://localhost:5173`
   - API at `http://localhost:8787`

## Example Output

After running the command, you'll have a fully functional app that you can:
- Start with `pnpm run dev`
- Connect to production services later with `pnpm connect:*` commands
- Deploy to Cloudflare Pages + Workers
- Customize with your own features

## Progressive Connection

Start local and connect production services when ready:
- `pnpm connect:auth` - Production Firebase Auth
- `pnpm connect:database` - Choose database provider  
- `pnpm connect:deploy` - Cloudflare deployment
- `pnpm connection:status` - Check current setup

