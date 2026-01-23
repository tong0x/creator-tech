import { Bot } from 'grammy';
import { config } from '../config/index.js';
import type { IngestedItem } from '../types/index.js';

export class TelegramIntegration {
  private bot: Bot | null = null;
  private chatIds: string[] = [];
  private messageBuffer: IngestedItem[] = [];

  constructor() {
    if (config.TELEGRAM_BOT_TOKEN) {
      this.bot = new Bot(config.TELEGRAM_BOT_TOKEN);
      this.chatIds = config.TELEGRAM_CHAT_IDS?.split(',').map(s => s.trim()) || [];
      this.setupListeners();
    }
  }

  isEnabled(): boolean {
    return this.bot !== null;
  }

  private setupListeners(): void {
    if (!this.bot) return;

    // Listen for all messages
    this.bot.on('message', (ctx) => {
      const chatId = ctx.chat.id.toString();

      // Only track messages from specified chats
      if (this.chatIds.length > 0 && !this.chatIds.includes(chatId)) {
        return;
      }

      const message = ctx.message;
      const sender = message.from?.first_name
        ? `${message.from.first_name} ${message.from.last_name || ''}`.trim()
        : message.from?.username || 'Unknown';

      this.messageBuffer.push({
        id: `telegram-${message.message_id}-${chatId}`,
        source: 'telegram',
        type: 'direct_message',
        title: `Message from ${sender}`,
        content: message.text || message.caption || '[Media]',
        sender,
        timestamp: new Date(message.date * 1000),
        rawData: message,
        metadata: {
          chatId,
          chatTitle: ctx.chat.type !== 'private' ? (ctx.chat as any).title : 'DM',
          messageId: message.message_id,
        },
      });
    });
  }

  async start(): Promise<void> {
    if (!this.bot) return;

    try {
      await this.bot.start({
        onStart: () => console.log('Telegram bot started'),
      });
    } catch (error) {
      console.error('Telegram bot start error:', error);
    }
  }

  stop(): void {
    this.bot?.stop();
  }

  getBufferedMessages(): IngestedItem[] {
    const messages = [...this.messageBuffer];
    this.messageBuffer = [];
    return messages;
  }

  getMessagesSince(since: Date): IngestedItem[] {
    return this.messageBuffer.filter(m => m.timestamp > since);
  }

  async sendMessage(chatId: string, text: string): Promise<void> {
    if (!this.bot) return;

    try {
      await this.bot.api.sendMessage(chatId, text, {
        parse_mode: 'Markdown',
      });
    } catch (error) {
      console.error('Telegram send error:', error);
    }
  }
}

export const telegramIntegration = new TelegramIntegration();
