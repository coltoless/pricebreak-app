# PriceBreak

AI-Powered Price Intelligence for Smart Ticket Shopping

## Overview

PriceBreak is a Ruby on Rails application that helps destination wedding guests find and purchase flights at the best possible prices. The application aggregates flight data from multiple airlines and travel agencies, providing dynamic pricing filters and auto-buy capabilities.

## Features

- **Flight Search & Aggregation**: Multi-airline search with dynamic pricing filters
- **Destination Wedding Focus**: Wedding-specific search templates and group booking coordination
- **Price Alerts & Auto-Buy**: Target price alerts with automatic booking capabilities
- **Real-time Updates**: WebSocket integration for live price updates
- **User Management**: Authentication and guest profile management

## Tech Stack

- Ruby on Rails 8.1.1
- PostgreSQL database
- Redis for caching and background jobs
- ActionCable for WebSocket connections
- Devise for authentication
- React/TypeScript frontend components

## Development

### Prerequisites

- Ruby 3.3.9
- Node.js 16.14.0+
- PostgreSQL
- Redis

### Setup

1. Clone the repository
2. Run `bin/setup` to install dependencies and prepare the database
3. Start the development server with `bin/dev`

### Cursor AI Commands

This project includes AI-powered development commands from the [VoloBuilds Prompts Repository](https://github.com/VoloBuilds/prompts/tree/main/commands) and [create-volo-app](https://github.com/VoloBuilds/create-volo-app). Use these in Cursor AI chat to streamline your workflow:

- `@create_brief.md` - Create product briefs and project context
- `@plan_feature.md` - Plan new features with technical requirements
- `@code_review.md` - Review completed code against plans
- `@write_docs.md` - Generate comprehensive documentation
- `@create_volo_app.md` - Generate new full-stack applications (React + TypeScript + Firebase + Postgres)

See `.cursor/commands/README.md` for detailed usage instructions.

## API Integrations

- Skyscanner API (primary)
- Amadeus API
- Google Flights API
- Kiwi.com API

## Contributing

1. Create a feature branch
2. Use the Cursor AI commands to plan and document your feature
3. Implement the feature
4. Submit a pull request

## License

ISC
