import { aiService } from './ai.js';
import { slackService } from './slack.js';
import {
  emailIntegration,
  githubIntegration,
  linearIntegration,
  telegramIntegration,
  twitterIntegration,
  calendarIntegration,
  marketIntegration,
  newsIntegration,
} from '../integrations/index.js';
import type { IngestedItem, ProcessedItem, DailyBriefing } from '../types/index.js';

export class BriefingService {
  private lastBriefingTime: Date | null = null;

  async generateMorningBriefing(): Promise<DailyBriefing> {
    console.log('Generating morning briefing...');

    // Get the time window (since last briefing or last 12 hours)
    const since = this.lastBriefingTime || new Date(Date.now() - 12 * 60 * 60 * 1000);

    // Fetch all data in parallel
    const [
      emails,
      githubNotifs,
      linearIssues,
      telegramMsgs,
      twitterMentions,
      calendar,
      btcData,
      economicEvents,
      cryptoNews,
    ] = await Promise.all([
      emailIntegration.getUnreadEmails(30),
      githubIntegration.getNotifications(since),
      linearIntegration.getAssignedIssues(),
      Promise.resolve(telegramIntegration.getMessagesSince(since)),
      twitterIntegration.getMentions(since),
      calendarIntegration.getTodayEvents(),
      marketIntegration.getBTCData(),
      marketIntegration.getEconomicCalendar(),
      newsIntegration.getCryptoNews(since, 10),
    ]);

    // Combine all messages
    const allMessages: IngestedItem[] = [
      ...emails,
      ...githubNotifs,
      ...linearIssues,
      ...telegramMsgs,
      ...twitterMentions,
    ];

    // Process each message with AI to determine priority
    console.log(`Processing ${allMessages.length} messages...`);
    const processedMessages: ProcessedItem[] = [];

    for (const msg of allMessages) {
      try {
        const processed = await aiService.processItem(msg);
        processedMessages.push(processed);
      } catch (error) {
        console.error(`Failed to process message ${msg.id}:`, error);
        // Add unprocessed with default priority
        processedMessages.push({
          ...msg,
          priority: 'medium',
          summary: msg.content.slice(0, 100),
          actionRequired: false,
          tags: [],
        });
      }
    }

    // Generate the briefing
    const briefing = await aiService.generateMorningBriefing({
      messages: processedMessages,
      calendar,
      market: btcData,
      economicEvents,
    });

    this.lastBriefingTime = new Date();

    return briefing;
  }

  async sendMorningBriefing(): Promise<void> {
    try {
      const briefing = await this.generateMorningBriefing();
      await slackService.sendMorningBriefing(briefing);
      console.log('Morning briefing sent successfully');
    } catch (error) {
      console.error('Failed to send morning briefing:', error);
      throw error;
    }
  }

  async generateQuickSummary(): Promise<string> {
    const since = new Date(Date.now() - 4 * 60 * 60 * 1000); // Last 4 hours

    const [emails, github, linear] = await Promise.all([
      emailIntegration.getUnreadEmails(10),
      githubIntegration.getNotifications(since),
      linearIntegration.getHighPriorityIssues(),
    ]);

    const totalUnread = emails.length;
    const githubItems = github.length;
    const highPriorityIssues = linear.length;

    return `Quick Summary:\n` +
      `- ${totalUnread} unread emails\n` +
      `- ${githubItems} GitHub notifications\n` +
      `- ${highPriorityIssues} high-priority Linear issues`;
  }

  async checkImportantMissedMessages(importantContacts: string[]): Promise<ProcessedItem[]> {
    const since = new Date(Date.now() - 6 * 60 * 60 * 1000); // Last 6 hours

    const [emails, slack, telegram] = await Promise.all([
      emailIntegration.getEmailsSince(since),
      slackService.getUnreadMessages(since),
      Promise.resolve(telegramIntegration.getMessagesSince(since)),
    ]);

    const allMessages: IngestedItem[] = [
      ...emails,
      ...slack.map(s => ({
        id: `slack-${s.ts}`,
        source: 'slack' as const,
        type: 'direct_message' as const,
        title: `Slack DM`,
        content: s.text || '',
        sender: s.user,
        timestamp: new Date(parseFloat(s.ts) * 1000),
        rawData: s,
      })),
      ...telegram,
    ];

    // Filter messages from important contacts
    const importantMessages = allMessages.filter(msg =>
      msg.sender && importantContacts.some(contact =>
        msg.sender!.toLowerCase().includes(contact.toLowerCase())
      )
    );

    // Process to get priority
    const processed: ProcessedItem[] = [];
    for (const msg of importantMessages) {
      const p = await aiService.processItem(msg, 'Message from important contact');
      processed.push(p);
    }

    return processed.filter(p => p.priority === 'critical' || p.priority === 'high');
  }
}

export const briefingService = new BriefingService();
