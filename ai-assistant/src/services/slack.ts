import { WebClient } from '@slack/web-api';
import { config } from '../config/index.js';
import type { NotificationPayload, ProcessedItem, DailyBriefing, Priority } from '../types/index.js';

export class SlackService {
  private client: WebClient;
  private userId: string;

  constructor() {
    this.client = new WebClient(config.SLACK_BOT_TOKEN);
    this.userId = config.SLACK_USER_ID;
  }

  async sendDirectMessage(text: string, blocks?: unknown[]): Promise<void> {
    try {
      // Open DM channel with user
      const dmChannel = await this.client.conversations.open({
        users: this.userId,
      });

      if (!dmChannel.channel?.id) {
        throw new Error('Failed to open DM channel');
      }

      await this.client.chat.postMessage({
        channel: dmChannel.channel.id,
        text,
        blocks: blocks as any,
      });
    } catch (error) {
      console.error('Failed to send Slack message:', error);
      throw error;
    }
  }

  async sendNotification(payload: NotificationPayload): Promise<void> {
    const blocks = payload.blocks || this.buildNotificationBlocks(payload);
    await this.sendDirectMessage(payload.body, blocks);
  }

  async sendMorningBriefing(briefing: DailyBriefing): Promise<void> {
    const blocks = this.buildBriefingBlocks(briefing);
    await this.sendDirectMessage(`Good morning! Here's your briefing for ${briefing.date.toLocaleDateString()}`, blocks);
  }

  async sendPriorityAlert(item: ProcessedItem): Promise<void> {
    const emoji = this.getPriorityEmoji(item.priority);
    const blocks = [
      {
        type: 'header',
        text: {
          type: 'plain_text',
          text: `${emoji} ${item.priority.toUpperCase()} Priority Alert`,
        },
      },
      {
        type: 'section',
        text: {
          type: 'mrkdwn',
          text: `*${item.title}*\n${item.summary}`,
        },
      },
      {
        type: 'context',
        elements: [
          {
            type: 'mrkdwn',
            text: `Source: *${item.source}* | From: ${item.sender || 'Unknown'} | ${item.timestamp.toLocaleTimeString()}`,
          },
        ],
      },
    ];

    if (item.actionRequired && item.suggestedAction) {
      blocks.push({
        type: 'section',
        text: {
          type: 'mrkdwn',
          text: `*Suggested Action:* ${item.suggestedAction}`,
        },
      });
    }

    if (item.url) {
      blocks.push({
        type: 'actions',
        elements: [
          {
            type: 'button',
            text: { type: 'plain_text', text: 'View Original' },
            url: item.url,
          },
        ],
      } as any);
    }

    await this.sendDirectMessage(item.summary, blocks);
  }

  async sendMarketAlert(message: string, data: Record<string, unknown>): Promise<void> {
    const blocks = [
      {
        type: 'header',
        text: {
          type: 'plain_text',
          text: '📊 Market Alert',
        },
      },
      {
        type: 'section',
        text: {
          type: 'mrkdwn',
          text: message,
        },
      },
      {
        type: 'context',
        elements: [
          {
            type: 'mrkdwn',
            text: `Price: $${data.price} | 24h: ${data.change24h}% | RSI: ${data.rsi || 'N/A'}`,
          },
        ],
      },
    ];

    await this.sendDirectMessage(message, blocks);
  }

  private buildNotificationBlocks(payload: NotificationPayload): unknown[] {
    return [
      {
        type: 'header',
        text: {
          type: 'plain_text',
          text: payload.title,
        },
      },
      {
        type: 'section',
        text: {
          type: 'mrkdwn',
          text: payload.body,
        },
      },
    ];
  }

  private buildBriefingBlocks(briefing: DailyBriefing): unknown[] {
    const blocks: unknown[] = [
      {
        type: 'header',
        text: {
          type: 'plain_text',
          text: `☀️ Morning Briefing - ${briefing.date.toLocaleDateString('en-US', { weekday: 'long', month: 'long', day: 'numeric' })}`,
        },
      },
      { type: 'divider' },
    ];

    // AI Summary
    blocks.push({
      type: 'section',
      text: {
        type: 'mrkdwn',
        text: `*Summary*\n${briefing.summary}`,
      },
    });

    // Priority items
    if (briefing.priorityItems.length > 0) {
      blocks.push({ type: 'divider' });
      blocks.push({
        type: 'section',
        text: {
          type: 'mrkdwn',
          text: `*🚨 Priority Items (${briefing.priorityItems.length})*`,
        },
      });

      for (const item of briefing.priorityItems.slice(0, 5)) {
        blocks.push({
          type: 'section',
          text: {
            type: 'mrkdwn',
            text: `${this.getPriorityEmoji(item.priority)} *${item.title}*\n${item.summary}`,
          },
        });
      }
    }

    // Today's calendar
    if (briefing.upcomingEvents.length > 0) {
      blocks.push({ type: 'divider' });
      blocks.push({
        type: 'section',
        text: {
          type: 'mrkdwn',
          text: `*📅 Today's Schedule (${briefing.upcomingEvents.length} events)*`,
        },
      });

      for (const event of briefing.upcomingEvents.slice(0, 5)) {
        const time = event.isAllDay
          ? 'All day'
          : event.startTime.toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' });
        blocks.push({
          type: 'section',
          text: {
            type: 'mrkdwn',
            text: `• *${time}* - ${event.title}`,
          },
        });
      }
    }

    // Market overview
    if (briefing.marketSummary.btc) {
      blocks.push({ type: 'divider' });
      const btc = briefing.marketSummary.btc;
      const changeEmoji = btc.change24h >= 0 ? '📈' : '📉';
      blocks.push({
        type: 'section',
        text: {
          type: 'mrkdwn',
          text: `*${changeEmoji} Market Overview*\n` +
            `BTC: $${btc.price.toLocaleString()} (${btc.change24h >= 0 ? '+' : ''}${btc.change24h.toFixed(2)}%)\n` +
            (btc.indicators?.rsi ? `RSI: ${btc.indicators.rsi.toFixed(1)}` : ''),
        },
      });
    }

    // Economic events
    if (briefing.economicCalendar.length > 0) {
      blocks.push({ type: 'divider' });
      blocks.push({
        type: 'section',
        text: {
          type: 'mrkdwn',
          text: `*🏛️ Economic Calendar*`,
        },
      });

      for (const event of briefing.economicCalendar.slice(0, 3)) {
        const importance = event.importance === 'high' ? '🔴' : event.importance === 'medium' ? '🟡' : '⚪';
        blocks.push({
          type: 'section',
          text: {
            type: 'mrkdwn',
            text: `${importance} *${event.title}* (${event.country})\n` +
              `${event.date.toLocaleDateString()} ${event.date.toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' })}`,
          },
        });
      }
    }

    // Unread messages summary
    if (briefing.unreadMessages.length > 0) {
      blocks.push({ type: 'divider' });
      blocks.push({
        type: 'section',
        text: {
          type: 'mrkdwn',
          text: `*💬 Unread Messages: ${briefing.unreadMessages.length}*\n` +
            briefing.unreadMessages.slice(0, 3).map(m => `• ${m.source}: ${m.title}`).join('\n'),
        },
      });
    }

    return blocks;
  }

  private getPriorityEmoji(priority: Priority): string {
    const emojis: Record<Priority, string> = {
      critical: '🚨',
      high: '🔴',
      medium: '🟡',
      low: '🟢',
      fyi: 'ℹ️',
    };
    return emojis[priority];
  }

  // Fetch unread Slack messages (mentions, DMs)
  async getUnreadMessages(since: Date): Promise<any[]> {
    try {
      // Get DMs
      const dms = await this.client.conversations.list({
        types: 'im',
      });

      const messages: any[] = [];

      for (const channel of dms.channels || []) {
        if (!channel.id) continue;

        const history = await this.client.conversations.history({
          channel: channel.id,
          oldest: (since.getTime() / 1000).toString(),
        });

        for (const msg of history.messages || []) {
          if (msg.user !== this.userId) {
            messages.push({
              ...msg,
              channelId: channel.id,
              type: 'dm',
            });
          }
        }
      }

      return messages;
    } catch (error) {
      console.error('Failed to fetch Slack messages:', error);
      return [];
    }
  }
}

export const slackService = new SlackService();
