# AI Executive Assistant

An AI-powered executive assistant that monitors multiple channels and proactively keeps you updated via Slack.

## Features

- **Morning Briefing** - Wake up to a comprehensive summary of:
  - Important messages you missed overnight
  - Today's calendar events
  - Market conditions (BTC, etc.)
  - Upcoming economic events (Fed meetings, rate decisions)

- **Real-time Alerts**
  - Important messages from priority contacts
  - GitHub PR reviews, mentions, issues
  - Linear issue assignments and comments
  - BTC momentum/directional moves
  - Calendar reminders (15 min before meetings)

- **Integrations**
  - Slack (primary notification channel)
  - Gmail
  - Google Calendar
  - GitHub
  - Linear
  - Telegram
  - X/Twitter
  - Crypto/Market data (CoinGecko)
  - News RSS feeds

## Setup

### 1. Install dependencies

```bash
cd ai-assistant
npm install
```

### 2. Configure environment

```bash
cp .env.example .env
# Edit .env with your API keys
```

### Required credentials:

| Service | What you need |
|---------|---------------|
| Claude AI | Anthropic API key |
| Slack | Bot token, App token, User ID |
| Google | OAuth client ID/secret, refresh token |
| GitHub | Personal access token |
| Linear | API key |
| Telegram | Bot token |
| X/Twitter | API keys and tokens |

### 3. Slack App Setup

1. Create a new Slack app at https://api.slack.com/apps
2. Add these Bot Token Scopes:
   - `chat:write`
   - `im:write`
   - `im:read`
   - `im:history`
   - `users:read`
3. Install to workspace and copy the Bot Token
4. Get your Slack User ID (click profile > ... > Copy member ID)

### 4. Google OAuth Setup

1. Create OAuth credentials in Google Cloud Console
2. Enable Gmail API and Calendar API
3. Use the OAuth playground or a script to get refresh token

## Usage

### Start the assistant

```bash
npm run dev     # Development with hot reload
npm start       # Production
```

### Manual morning briefing

```bash
npm run morning-briefing
```

## Configuration

Edit preferences in `src/index.ts`:

```typescript
const preferences: Partial<UserPreferences> = {
  // When to send morning briefing
  morningBriefingTime: '07:00',

  // Don't disturb during these hours
  quietHoursStart: '22:00',
  quietHoursEnd: '07:00',

  // Watch these GitHub repos
  watchedGithubRepos: ['your-org/your-repo'],

  // Always notify for these contacts
  importantContacts: ['ceo@company.com', '@important_person'],

  // BTC momentum threshold (%)
  btcMomentumThreshold: 5,

  // Price alerts
  priceAlertLevels: [
    { symbol: 'BTC', above: 100000, below: 90000 },
  ],
};
```

## Architecture

```
src/
├── config/         # Environment and configuration
├── types/          # TypeScript type definitions
├── integrations/   # External service connectors
│   ├── email.ts    # Gmail integration
│   ├── calendar.ts # Google Calendar
│   ├── github.ts   # GitHub notifications
│   ├── linear.ts   # Linear issues
│   ├── telegram.ts # Telegram messages
│   ├── twitter.ts  # X/Twitter
│   ├── market.ts   # Crypto/market data
│   └── news.ts     # RSS news feeds
├── services/       # Core business logic
│   ├── ai.ts       # Claude AI processing
│   ├── slack.ts    # Slack notifications
│   ├── briefing.ts # Morning briefing generation
│   └── scheduler.ts # Cron job management
└── scripts/        # Manual trigger scripts
```

## How It Works

1. **Scheduler** runs cron jobs for:
   - Morning briefing (configurable time)
   - Market checks (every 5 min)
   - Calendar reminders (every minute)
   - Important message checks (every 15 min)

2. **Integrations** fetch data from various sources

3. **AI Service** processes messages to determine:
   - Priority (critical/high/medium/low/fyi)
   - Whether action is required
   - Suggested actions
   - Summarization

4. **Slack Service** sends formatted notifications

## License

MIT
