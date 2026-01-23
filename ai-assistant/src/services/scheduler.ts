import cron from 'node-cron';
import { config } from '../config/index.js';
import { briefingService } from './briefing.js';
import { slackService } from './slack.js';
import { aiService } from './ai.js';
import { marketIntegration, calendarIntegration } from '../integrations/index.js';
import type { UserPreferences } from '../types/index.js';

export class SchedulerService {
  private jobs: cron.ScheduledTask[] = [];
  private preferences: UserPreferences;
  private lastMarketAlert: Date | null = null;

  constructor(preferences: Partial<UserPreferences> = {}) {
    this.preferences = {
      timezone: config.TIMEZONE,
      morningBriefingTime: config.MORNING_BRIEFING_TIME,
      quietHoursStart: config.QUIET_HOURS_START,
      quietHoursEnd: config.QUIET_HOURS_END,
      watchedSymbols: ['BTC', 'ETH'],
      watchedGithubRepos: [],
      importantContacts: [],
      priorityKeywords: [],
      btcMomentumThreshold: 5,
      priceAlertLevels: [],
      enableRealTimeAlerts: true,
      enableMorningBriefing: true,
      digestMode: 'realtime',
      ...preferences,
    };
  }

  start(): void {
    console.log('Starting scheduler...');

    // Morning briefing
    if (this.preferences.enableMorningBriefing) {
      const [hour, minute] = this.preferences.morningBriefingTime.split(':');
      const cronTime = `${minute} ${hour} * * *`;

      const morningJob = cron.schedule(cronTime, async () => {
        console.log('Running morning briefing...');
        try {
          await briefingService.sendMorningBriefing();
        } catch (error) {
          console.error('Morning briefing failed:', error);
        }
      }, {
        timezone: this.preferences.timezone,
      });

      this.jobs.push(morningJob);
      console.log(`Morning briefing scheduled for ${this.preferences.morningBriefingTime}`);
    }

    // Market monitoring (every 5 minutes)
    const marketJob = cron.schedule('*/5 * * * *', async () => {
      await this.checkMarkets();
    });
    this.jobs.push(marketJob);
    console.log('Market monitoring scheduled (every 5 minutes)');

    // Calendar reminders (every minute)
    const calendarJob = cron.schedule('* * * * *', async () => {
      await this.checkCalendarReminders();
    });
    this.jobs.push(calendarJob);
    console.log('Calendar reminders scheduled (every minute)');

    // Important message check (every 15 minutes)
    const messageJob = cron.schedule('*/15 * * * *', async () => {
      await this.checkImportantMessages();
    });
    this.jobs.push(messageJob);
    console.log('Important message check scheduled (every 15 minutes)');

    // Economic calendar check (daily at 8am)
    const econJob = cron.schedule('0 8 * * *', async () => {
      await this.checkEconomicCalendar();
    }, {
      timezone: this.preferences.timezone,
    });
    this.jobs.push(econJob);
    console.log('Economic calendar check scheduled (daily at 8am)');

    console.log('Scheduler started successfully');
  }

  stop(): void {
    for (const job of this.jobs) {
      job.stop();
    }
    this.jobs = [];
    console.log('Scheduler stopped');
  }

  private isQuietHours(): boolean {
    const now = new Date();
    const currentHour = now.getHours();
    const currentMinute = now.getMinutes();
    const currentTime = currentHour * 60 + currentMinute;

    const [startHour, startMinute] = this.preferences.quietHoursStart.split(':').map(Number);
    const [endHour, endMinute] = this.preferences.quietHoursEnd.split(':').map(Number);

    const startTime = startHour * 60 + startMinute;
    const endTime = endHour * 60 + endMinute;

    if (startTime > endTime) {
      // Quiet hours span midnight
      return currentTime >= startTime || currentTime < endTime;
    }

    return currentTime >= startTime && currentTime < endTime;
  }

  private async checkMarkets(): Promise<void> {
    if (this.isQuietHours()) return;

    try {
      const btcData = await marketIntegration.getBTCData();

      // Check for momentum alerts
      const alert = marketIntegration.checkMomentumAlert(btcData, this.preferences.btcMomentumThreshold);

      if (alert) {
        // Debounce: don't alert more than once per hour
        if (this.lastMarketAlert && Date.now() - this.lastMarketAlert.getTime() < 60 * 60 * 1000) {
          return;
        }

        // Get AI analysis
        const analysis = await aiService.analyzeMarketMomentum(btcData);

        if (analysis.hasMomentum) {
          const message = `*${analysis.direction.toUpperCase()} Momentum Detected*\n\n` +
            `${alert.message}\n\n` +
            `_${analysis.analysis}_\n\n` +
            `Strength: ${analysis.strength}/100`;

          await slackService.sendMarketAlert(message, {
            price: btcData.price,
            change24h: btcData.change24h.toFixed(2),
            rsi: btcData.indicators?.rsi?.toFixed(1),
          });

          this.lastMarketAlert = new Date();
        }
      }

      // Check price level alerts
      for (const level of this.preferences.priceAlertLevels) {
        if (level.symbol !== 'BTC') continue;

        if (level.above && btcData.price > level.above) {
          await slackService.sendDirectMessage(
            `BTC crossed above $${level.above.toLocaleString()} - now at $${btcData.price.toLocaleString()}`
          );
        }

        if (level.below && btcData.price < level.below) {
          await slackService.sendDirectMessage(
            `BTC dropped below $${level.below.toLocaleString()} - now at $${btcData.price.toLocaleString()}`
          );
        }
      }
    } catch (error) {
      console.error('Market check error:', error);
    }
  }

  private async checkCalendarReminders(): Promise<void> {
    if (this.isQuietHours()) return;

    try {
      const upcomingEvents = await calendarIntegration.getEventReminders(15);

      for (const event of upcomingEvents) {
        const minutesUntil = Math.round(
          (event.startTime.getTime() - Date.now()) / (60 * 1000)
        );

        await slackService.sendDirectMessage(
          `Reminder: *${event.title}* starts in ${minutesUntil} minutes` +
          (event.location ? `\nLocation: ${event.location}` : '') +
          (event.attendees?.length ? `\nWith: ${event.attendees.slice(0, 3).join(', ')}` : '')
        );
      }
    } catch (error) {
      console.error('Calendar reminder check error:', error);
    }
  }

  private async checkImportantMessages(): Promise<void> {
    if (this.isQuietHours() || this.preferences.importantContacts.length === 0) return;

    try {
      const important = await briefingService.checkImportantMissedMessages(
        this.preferences.importantContacts
      );

      for (const msg of important) {
        await slackService.sendPriorityAlert(msg);
      }
    } catch (error) {
      console.error('Important message check error:', error);
    }
  }

  private async checkEconomicCalendar(): Promise<void> {
    try {
      const events = await marketIntegration.getEconomicCalendar();
      const highImportance = events.filter(e => e.importance === 'high');

      if (highImportance.length === 0) return;

      const upcomingWeek = highImportance.filter(e => {
        const daysUntil = (e.date.getTime() - Date.now()) / (24 * 60 * 60 * 1000);
        return daysUntil <= 7 && daysUntil >= 0;
      });

      if (upcomingWeek.length > 0) {
        const message = `*Upcoming Economic Events*\n\n` +
          upcomingWeek.map(e => {
            const daysUntil = Math.ceil((e.date.getTime() - Date.now()) / (24 * 60 * 60 * 1000));
            return `• *${e.title}* (${e.country})\n  ${e.date.toLocaleDateString()} - ${daysUntil === 0 ? 'Today' : `in ${daysUntil} days`}`;
          }).join('\n\n');

        await slackService.sendDirectMessage(message);
      }
    } catch (error) {
      console.error('Economic calendar check error:', error);
    }
  }

  updatePreferences(updates: Partial<UserPreferences>): void {
    this.preferences = { ...this.preferences, ...updates };

    // Restart scheduler with new preferences
    this.stop();
    this.start();
  }
}

export const createScheduler = (preferences?: Partial<UserPreferences>) =>
  new SchedulerService(preferences);
