import { z } from 'zod';
import dotenv from 'dotenv';

dotenv.config();

const envSchema = z.object({
  // AI
  ANTHROPIC_API_KEY: z.string().min(1),

  // Slack
  SLACK_BOT_TOKEN: z.string().startsWith('xoxb-'),
  SLACK_APP_TOKEN: z.string().startsWith('xapp-').optional(),
  SLACK_SIGNING_SECRET: z.string().optional(),
  SLACK_USER_ID: z.string().min(1),

  // Google
  GOOGLE_CLIENT_ID: z.string().optional(),
  GOOGLE_CLIENT_SECRET: z.string().optional(),
  GOOGLE_REFRESH_TOKEN: z.string().optional(),

  // GitHub
  GITHUB_TOKEN: z.string().optional(),

  // Linear
  LINEAR_API_KEY: z.string().optional(),

  // Telegram
  TELEGRAM_BOT_TOKEN: z.string().optional(),
  TELEGRAM_CHAT_IDS: z.string().optional(),

  // X/Twitter
  X_API_KEY: z.string().optional(),
  X_API_SECRET: z.string().optional(),
  X_ACCESS_TOKEN: z.string().optional(),
  X_ACCESS_SECRET: z.string().optional(),

  // Infrastructure
  REDIS_URL: z.string().default('redis://localhost:6379'),
  DATABASE_URL: z.string().optional(),

  // Preferences
  TIMEZONE: z.string().default('America/Los_Angeles'),
  MORNING_BRIEFING_TIME: z.string().default('07:00'),
  QUIET_HOURS_START: z.string().default('22:00'),
  QUIET_HOURS_END: z.string().default('07:00'),
});

function loadConfig() {
  const parsed = envSchema.safeParse(process.env);

  if (!parsed.success) {
    console.error('❌ Invalid environment variables:');
    console.error(parsed.error.format());
    throw new Error('Invalid environment configuration');
  }

  return parsed.data;
}

export const config = loadConfig();

export const isIntegrationEnabled = {
  slack: () => !!config.SLACK_BOT_TOKEN,
  google: () => !!config.GOOGLE_CLIENT_ID && !!config.GOOGLE_REFRESH_TOKEN,
  github: () => !!config.GITHUB_TOKEN,
  linear: () => !!config.LINEAR_API_KEY,
  telegram: () => !!config.TELEGRAM_BOT_TOKEN,
  twitter: () => !!config.X_API_KEY && !!config.X_ACCESS_TOKEN,
};
