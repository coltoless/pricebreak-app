# Cursor Commands from VoloBuilds Prompts

This directory contains AI prompts that can be used in Cursor AI chat to streamline your development workflow. These commands are designed to help with common development tasks like planning features, creating briefs, and reviewing code.

## How to Use

In Cursor AI chat, you can reference these commands using the `@` symbol followed by the filename. For example:

- `@create_brief.md` - Create a product brief
- `@plan_feature.md` - Plan a new feature
- `@code_review.md` - Review completed code
- `@write_docs.md` - Write comprehensive documentation
- `@create_volo_app.md` - Generate a new full-stack application

## Available Commands

### 1. Create Brief (`@create_brief.md`)
Use this when you need to establish the bigger picture context of what your project is about. Helpful for planning new features or onboarding team members.

**Example usage:**
```
@create_brief.md

We are building a flight search application called PriceBreak that helps destination wedding guests find the best flight deals. It will include multi-airline search, price alerts, and auto-buy functionality.
```

### 2. Plan Feature (`@plan_feature.md`)
Use this to create a technical plan for a new feature. Focuses on technical requirements and implementation details.

**Example usage:**
```
@plan_feature.md

We want to add a new wedding-specific search template that automatically suggests optimal flight dates around wedding dates and provides group booking coordination features.
```

### 3. Code Review (`@code_review.md`)
Use this to review the successful completion of a plan in a separate chat.

**Example usage:**
```
@code_review.md
@0001_PLAN.md
```

### 4. Write Documentation (`@write_docs.md`)
Use this to create comprehensive documentation for plans, reviews, and implementation.

**Example usage:**
```
@write_docs.md
@0001_PLAN.md
@0001_REVIEW.md
```

### 5. Create Volo App (`@create_volo_app.md`)
Use this to generate a new full-stack application using the VoloBuilds create-volo-app starter kit. Perfect for rapid prototyping and starting new projects.

**Example usage:**
```
@create_volo_app.md

Create a new app called "my-todo-app" for local development
```

**What you get:**
- React + TypeScript + Vite frontend
- Tailwind CSS + ShadCN components
- Firebase Authentication
- Hono API backend (NodeJS)
- PostgreSQL database with Drizzle ORM
- Working app in under 30 seconds!

## Workflow

The typical workflow using these commands is:

1. **Create Brief** - Establish project context
2. **Plan Feature** - Create technical implementation plan
3. **Implement** - Build the feature (in a separate chat)
4. **Code Review** - Review the implementation against the plan
5. **Write Docs** - Document the complete feature

**For new projects:**
1. **Create Volo App** - Generate a new full-stack application
2. **Create Brief** - Establish project context
3. **Plan Features** - Plan your application features
4. **Implement** - Build your application
5. **Review & Document** - Review code and write documentation

## Source

These commands are sourced from the [VoloBuilds Prompts Repository](https://github.com/VoloBuilds/prompts/tree/main/commands) and [create-volo-app](https://github.com/VoloBuilds/create-volo-app) and have been customized for use with the PriceBreak project.

## Customization

Feel free to customize these commands to better fit your specific project needs. The commands are designed as starting points and can be modified as your workflow evolves.
