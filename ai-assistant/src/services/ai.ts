import Anthropic from '@anthropic-ai/sdk';
import { config } from '../config/index.js';
import type {
  IngestedItem,
  ProcessedItem,
  Priority,
  DailyBriefing,
  MarketData,
  CalendarEvent,
  EconomicEvent,
} from '../types/index.js';

export class AIService {
  private client: Anthropic;

  constructor() {
    this.client = new Anthropic({
      apiKey: config.ANTHROPIC_API_KEY,
    });
  }

  async processItem(item: IngestedItem, context?: string): Promise<ProcessedItem> {
    const prompt = `You are an executive assistant AI. Analyze this incoming message/item and provide:
1. Priority level (critical, high, medium, low, fyi)
2. A brief summary (1-2 sentences)
3. Whether action is required (true/false)
4. Suggested action if applicable
5. Relevant tags

Context about the user: ${context || 'Tech founder, interested in crypto/web3, busy schedule'}

Item to analyze:
- Source: ${item.source}
- Type: ${item.type}
- From: ${item.sender || 'Unknown'}
- Title: ${item.title}
- Content: ${item.content}
- Time: ${item.timestamp.toISOString()}

Respond in JSON format:
{
  "priority": "high",
  "summary": "...",
  "actionRequired": true,
  "suggestedAction": "...",
  "tags": ["urgent", "meeting", ...]
}`;

    const response = await this.client.messages.create({
      model: 'claude-sonnet-4-20250514',
      max_tokens: 500,
      messages: [{ role: 'user', content: prompt }],
    });

    const text = response.content[0].type === 'text' ? response.content[0].text : '';
    const jsonMatch = text.match(/\{[\s\S]*\}/);

    if (!jsonMatch) {
      return {
        ...item,
        priority: 'medium',
        summary: item.content.slice(0, 100),
        actionRequired: false,
        tags: [],
      };
    }

    const analysis = JSON.parse(jsonMatch[0]);

    return {
      ...item,
      priority: analysis.priority as Priority,
      summary: analysis.summary,
      actionRequired: analysis.actionRequired,
      suggestedAction: analysis.suggestedAction,
      tags: analysis.tags || [],
    };
  }

  async generateMorningBriefing(data: {
    messages: ProcessedItem[];
    calendar: CalendarEvent[];
    market: MarketData;
    economicEvents: EconomicEvent[];
  }): Promise<DailyBriefing> {
    const prompt = `You are an executive assistant AI. Create a morning briefing summary.

Data:
- Unread messages: ${data.messages.length}
${data.messages.slice(0, 10).map(m => `  - [${m.source}/${m.priority}] ${m.title}: ${m.summary}`).join('\n')}

- Today's calendar: ${data.calendar.length} events
${data.calendar.map(e => `  - ${e.startTime.toLocaleTimeString()}: ${e.title}`).join('\n')}

- BTC: $${data.market.price.toLocaleString()} (${data.market.change24h}% 24h)
  RSI: ${data.market.indicators?.rsi || 'N/A'}
  Momentum: ${data.market.indicators?.momentum || 'N/A'}

- Economic Calendar:
${data.economicEvents.map(e => `  - [${e.importance}] ${e.title} (${e.country}) - ${e.date.toLocaleDateString()}`).join('\n')}

Write a concise morning briefing summary (3-5 sentences) highlighting:
1. Most important items requiring attention
2. Key meetings/events today
3. Market conditions
4. Any upcoming economic events to watch

Keep it actionable and concise.`;

    const response = await this.client.messages.create({
      model: 'claude-sonnet-4-20250514',
      max_tokens: 500,
      messages: [{ role: 'user', content: prompt }],
    });

    const summary = response.content[0].type === 'text' ? response.content[0].text : '';

    // Sort messages by priority
    const priorityOrder: Record<Priority, number> = {
      critical: 0,
      high: 1,
      medium: 2,
      low: 3,
      fyi: 4,
    };

    const priorityItems = data.messages
      .filter(m => m.priority === 'critical' || m.priority === 'high')
      .sort((a, b) => priorityOrder[a.priority] - priorityOrder[b.priority]);

    return {
      date: new Date(),
      unreadMessages: data.messages,
      upcomingEvents: data.calendar,
      marketSummary: { btc: data.market },
      economicCalendar: data.economicEvents,
      priorityItems,
      summary,
    };
  }

  async analyzeMarketMomentum(data: MarketData): Promise<{
    hasMomentum: boolean;
    direction: 'bullish' | 'bearish' | 'neutral';
    strength: number;
    analysis: string;
  }> {
    const prompt = `Analyze this market data for BTC and determine if there's significant directional momentum:

Price: $${data.price.toLocaleString()}
24h Change: ${data.change24h}%
Volume: $${data.volume24h.toLocaleString()}
RSI: ${data.indicators?.rsi || 'N/A'}
MACD: ${data.indicators?.macd ? `Value: ${data.indicators.macd.value}, Signal: ${data.indicators.macd.signal}` : 'N/A'}
EMA: ${data.indicators?.ema ? `Short: ${data.indicators.ema.short}, Long: ${data.indicators.ema.long}` : 'N/A'}

Respond in JSON:
{
  "hasMomentum": true/false,
  "direction": "bullish" | "bearish" | "neutral",
  "strength": 0-100,
  "analysis": "Brief explanation"
}

Only set hasMomentum=true if there's a clear, tradeable directional move happening.`;

    const response = await this.client.messages.create({
      model: 'claude-sonnet-4-20250514',
      max_tokens: 300,
      messages: [{ role: 'user', content: prompt }],
    });

    const text = response.content[0].type === 'text' ? response.content[0].text : '';
    const jsonMatch = text.match(/\{[\s\S]*\}/);

    if (!jsonMatch) {
      return {
        hasMomentum: false,
        direction: 'neutral',
        strength: 0,
        analysis: 'Unable to analyze',
      };
    }

    return JSON.parse(jsonMatch[0]);
  }

  async shouldNotifyUser(item: ProcessedItem, preferences: { quietHours: boolean; importantContacts: string[] }): Promise<boolean> {
    // Always notify for critical
    if (item.priority === 'critical') return true;

    // Don't notify during quiet hours unless critical
    if (preferences.quietHours && item.priority !== 'high') return false;

    // Always notify for important contacts
    if (item.sender && preferences.importantContacts.includes(item.sender)) return true;

    // Notify for high priority items
    if (item.priority === 'high') return true;

    return false;
  }
}

export const aiService = new AIService();
