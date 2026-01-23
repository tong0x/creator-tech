import { google } from 'googleapis';
import { config } from '../config/index.js';
import type { IngestedItem } from '../types/index.js';

export class EmailIntegration {
  private gmail: ReturnType<typeof google.gmail> | null = null;

  constructor() {
    if (config.GOOGLE_CLIENT_ID && config.GOOGLE_CLIENT_SECRET && config.GOOGLE_REFRESH_TOKEN) {
      const oauth2Client = new google.auth.OAuth2(
        config.GOOGLE_CLIENT_ID,
        config.GOOGLE_CLIENT_SECRET
      );

      oauth2Client.setCredentials({
        refresh_token: config.GOOGLE_REFRESH_TOKEN,
      });

      this.gmail = google.gmail({ version: 'v1', auth: oauth2Client });
    }
  }

  isEnabled(): boolean {
    return this.gmail !== null;
  }

  async getUnreadEmails(maxResults: number = 20): Promise<IngestedItem[]> {
    if (!this.gmail) return [];

    try {
      const response = await this.gmail.users.messages.list({
        userId: 'me',
        q: 'is:unread',
        maxResults,
      });

      const messages = response.data.messages || [];
      const items: IngestedItem[] = [];

      for (const msg of messages) {
        if (!msg.id) continue;

        const detail = await this.gmail.users.messages.get({
          userId: 'me',
          id: msg.id,
          format: 'metadata',
          metadataHeaders: ['From', 'Subject', 'Date'],
        });

        const headers = detail.data.payload?.headers || [];
        const getHeader = (name: string) => headers.find(h => h.name === name)?.value || '';

        const from = getHeader('From');
        const subject = getHeader('Subject');
        const date = getHeader('Date');

        items.push({
          id: `email-${msg.id}`,
          source: 'email',
          type: 'direct_message',
          title: subject,
          content: detail.data.snippet || '',
          sender: this.extractSenderName(from),
          url: `https://mail.google.com/mail/u/0/#inbox/${msg.id}`,
          timestamp: new Date(date),
          rawData: detail.data,
          metadata: {
            threadId: detail.data.threadId,
            labelIds: detail.data.labelIds,
            from,
          },
        });
      }

      return items;
    } catch (error) {
      console.error('Email fetch error:', error);
      return [];
    }
  }

  async getEmailsSince(since: Date, maxResults: number = 50): Promise<IngestedItem[]> {
    if (!this.gmail) return [];

    try {
      const afterTimestamp = Math.floor(since.getTime() / 1000);
      const response = await this.gmail.users.messages.list({
        userId: 'me',
        q: `after:${afterTimestamp}`,
        maxResults,
      });

      const messages = response.data.messages || [];
      const items: IngestedItem[] = [];

      for (const msg of messages) {
        if (!msg.id) continue;

        const detail = await this.gmail.users.messages.get({
          userId: 'me',
          id: msg.id,
          format: 'metadata',
          metadataHeaders: ['From', 'Subject', 'Date'],
        });

        const headers = detail.data.payload?.headers || [];
        const getHeader = (name: string) => headers.find(h => h.name === name)?.value || '';

        const from = getHeader('From');
        const subject = getHeader('Subject');
        const date = getHeader('Date');

        items.push({
          id: `email-${msg.id}`,
          source: 'email',
          type: 'direct_message',
          title: subject,
          content: detail.data.snippet || '',
          sender: this.extractSenderName(from),
          url: `https://mail.google.com/mail/u/0/#inbox/${msg.id}`,
          timestamp: new Date(date),
          rawData: detail.data,
          metadata: {
            threadId: detail.data.threadId,
            labelIds: detail.data.labelIds,
            from,
            isUnread: detail.data.labelIds?.includes('UNREAD'),
          },
        });
      }

      return items;
    } catch (error) {
      console.error('Email fetch error:', error);
      return [];
    }
  }

  private extractSenderName(from: string): string {
    // "John Doe <john@example.com>" -> "John Doe"
    const match = from.match(/^([^<]+)/);
    return match ? match[1].trim().replace(/"/g, '') : from;
  }
}

export const emailIntegration = new EmailIntegration();
