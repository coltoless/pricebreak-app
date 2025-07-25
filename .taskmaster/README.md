# TaskMaster AI Setup for PriceBreak - Flight Search

This directory contains the TaskMaster AI configuration for the PriceBreak flight search application, specifically designed for destination wedding guests.

## Project Focus
PriceBreak has been refactored to focus exclusively on airline ticket search and auto-buy functionality for destination weddings. The goal is to help wedding guests find and purchase flights at the best possible prices.

## Structure

- `docs/prd.txt` - Product Requirements Document (Flight-focused)
- `templates/` - Template files for tasks and documentation
- `tasks/` - Generated tasks will be stored here
- `config.json` - TaskMaster configuration

## Key Features Being Developed

### Flight Search & Aggregation
- Multi-airline search (Skyscanner, Amadeus, Google Flights, etc.)
- Wedding-specific search templates
- Dynamic pricing filters
- Group booking coordination

### Wedding-Specific Features
- Wedding date integration for optimal booking windows
- Guest list management
- Group rate negotiations
- Travel insurance recommendations

### Auto-Buy & Price Alerts
- Target price alerts
- Automatic booking when prices drop
- Price trend analysis
- Flexible date range monitoring

## Usage

Since this project is using Node.js 16.14.0 and TaskMaster AI requires Node.js 18+, you have a few options:

### Option 1: Upgrade Node.js (Recommended)
Upgrade to Node.js 18+ to use TaskMaster AI fully:

```bash
# Using nvm (Node Version Manager)
nvm install 18
nvm use 18

# Then initialize TaskMaster
npx task-master-ai init
```

### Option 2: Use Cursor AI with MCP
The MCP configuration has been set up in `~/.cursor/mcp.json`. You can:

1. Add your API keys to the MCP configuration
2. Enable TaskMaster in Cursor Settings (Ctrl+Shift+J) → MCP tab
3. Use TaskMaster commands in Cursor AI chat

### Option 3: Manual Task Management
Use the existing structure to manually manage tasks:

- Review the PRD in `docs/prd.txt`
- Create tasks manually in the `tasks/` directory
- Use the templates in `templates/` for consistency

## API Keys Required

To use TaskMaster AI, you'll need at least one of these API keys:

- Anthropic API key (for Claude)
- OpenAI API key
- Google Gemini API key
- Perplexity API key (for research)

Add your API keys to the MCP configuration in `~/.cursor/mcp.json`.

## Flight APIs Being Integrated

1. **Skyscanner API** (primary - implemented)
2. **Amadeus API** - Professional flight search
3. **Google Flights API** - Price comparison
4. **Kiwi.com API** - Alternative pricing
5. **Expedia API** - Package deals
6. **Kayak API** - Additional price comparison

## Common Commands

Once TaskMaster is properly set up, you can use:

- "Parse my PRD" - Generate tasks from the flight-focused PRD
- "What's the next task?" - Get the next task to work on
- "Show me task X" - View specific tasks
- "Help me implement task X" - Get assistance with implementation
- "Research flight API integration strategies" - Research with project context

## Development Timeline

**Goal**: Launch by wedding invitation date

### Phase 1: Core Flight Search (Current)
- ✅ Refactor application for flight focus
- 🔄 Update database schema
- ⏳ Implement flight search interface

### Phase 2: Wedding Features
- ⏳ Wedding-specific search templates
- ⏳ Group booking coordination
- ⏳ Guest list management

### Phase 3: Auto-Buy & Optimization
- ⏳ Advanced price prediction
- ⏳ Auto-buy functionality
- ⏳ Mobile optimization

## Success Metrics

- Successful flight bookings through the platform
- Price savings achieved for wedding guests
- User engagement with price alerts
- Guest satisfaction and ease of use
- Time saved in flight coordination 