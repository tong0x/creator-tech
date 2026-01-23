// Core types for the AI Executive Assistant

export type SourceType =
  | 'email'
  | 'slack'
  | 'telegram'
  | 'linear'
  | 'github'
  | 'twitter'
  | 'calendar'
  | 'market'
  | 'news';

export type Priority = 'critical' | 'high' | 'medium' | 'low' | 'fyi';

export type MessageType =
  | 'direct_message'
  | 'mention'
  | 'assignment'
  | 'review_request'
  | 'calendar_event'
  | 'market_alert'
  | 'economic_event'
  | 'news';

export interface IngestedItem {
  id: string;
  source: SourceType;
  type: MessageType;
  title: string;
  content: string;
  sender?: string;
  url?: string;
  timestamp: Date;
  rawData: unknown;
  metadata?: Record<string, unknown>;
}

export interface ProcessedItem extends IngestedItem {
  priority: Priority;
  summary: string;
  actionRequired: boolean;
  suggestedAction?: string;
  relatedItems?: string[]; // IDs of related items
  tags: string[];
}

export interface MarketData {
  symbol: string;
  price: number;
  change24h: number;
  volume24h: number;
  timestamp: Date;
  indicators?: {
    rsi?: number;
    macd?: { value: number; signal: number; histogram: number };
    ema?: { short: number; long: number };
    momentum?: number;
  };
}

export interface MarketAlert {
  symbol: string;
  alertType: 'momentum' | 'price_level' | 'volume_spike' | 'trend_change';
  message: string;
  data: MarketData;
  timestamp: Date;
}

export interface EconomicEvent {
  id: string;
  title: string;
  date: Date;
  importance: 'high' | 'medium' | 'low';
  country: string;
  forecast?: string;
  previous?: string;
  actual?: string;
}

export interface CalendarEvent {
  id: string;
  title: string;
  description?: string;
  startTime: Date;
  endTime: Date;
  attendees?: string[];
  location?: string;
  isAllDay: boolean;
}

export interface DailyBriefing {
  date: Date;
  unreadMessages: ProcessedItem[];
  upcomingEvents: CalendarEvent[];
  marketSummary: {
    btc: MarketData;
    eth?: MarketData;
    stocks?: MarketData[];
  };
  economicCalendar: EconomicEvent[];
  priorityItems: ProcessedItem[];
  summary: string;
}

export interface UserPreferences {
  timezone: string;
  morningBriefingTime: string;
  quietHoursStart: string;
  quietHoursEnd: string;

  // What to track
  watchedSymbols: string[];
  watchedGithubRepos: string[];
  importantContacts: string[];
  priorityKeywords: string[];

  // Alert thresholds
  btcMomentumThreshold: number;
  priceAlertLevels: { symbol: string; above?: number; below?: number }[];

  // Notification preferences
  enableRealTimeAlerts: boolean;
  enableMorningBriefing: boolean;
  digestMode: 'realtime' | 'hourly' | 'daily';
}

export interface NotificationPayload {
  channel: 'slack' | 'telegram';
  type: 'alert' | 'briefing' | 'digest' | 'reminder';
  title: string;
  body: string;
  blocks?: unknown[]; // Slack blocks
  priority: Priority;
  metadata?: Record<string, unknown>;
}
