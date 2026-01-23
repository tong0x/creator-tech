import { config } from './config/index.js';
import { createScheduler } from './services/scheduler.js';
import { telegramIntegration, marketIntegration } from './integrations/index.js';
import type { UserPreferences } from './types/index.js';

async function main() {
  console.log('Starting AI Executive Assistant...');
  console.log('================================');

  // Initialize market data with historical prices for indicators
  console.log('Initializing market data...');
  await marketIntegration.initializeWithHistoricalData();

  // Configure your preferences
  const preferences: Partial<UserPreferences> = {
    timezone: config.TIMEZONE,
    morningBriefingTime: config.MORNING_BRIEFING_TIME,
    quietHoursStart: config.QUIET_HOURS_START,
    quietHoursEnd: config.QUIET_HOURS_END,

    // Customize these
    watchedSymbols: ['BTC', 'ETH'],
    watchedGithubRepos: [
      // 'your-org/your-repo',
    ],
    importantContacts: [
      // 'important.person@email.com',
      // '@twitter_handle',
    ],
    priorityKeywords: [
      'urgent',
      'asap',
      'emergency',
      'deadline',
    ],
    btcMomentumThreshold: 5, // 5% movement triggers alert
    priceAlertLevels: [
      // { symbol: 'BTC', above: 100000, below: 90000 },
    ],
    enableRealTimeAlerts: true,
    enableMorningBriefing: true,
    digestMode: 'realtime',
  };

  // Start the scheduler
  const scheduler = createScheduler(preferences);
  scheduler.start();

  // Start Telegram bot if configured
  if (telegramIntegration.isEnabled()) {
    console.log('Starting Telegram bot...');
    telegramIntegration.start();
  }

  console.log('================================');
  console.log('AI Executive Assistant is running!');
  console.log(`Morning briefing: ${config.MORNING_BRIEFING_TIME}`);
  console.log(`Quiet hours: ${config.QUIET_HOURS_START} - ${config.QUIET_HOURS_END}`);
  console.log('Press Ctrl+C to stop.');

  // Handle graceful shutdown
  process.on('SIGINT', () => {
    console.log('\nShutting down...');
    scheduler.stop();
    telegramIntegration.stop();
    process.exit(0);
  });

  process.on('SIGTERM', () => {
    console.log('\nShutting down...');
    scheduler.stop();
    telegramIntegration.stop();
    process.exit(0);
  });
}

main().catch(error => {
  console.error('Fatal error:', error);
  process.exit(1);
});
