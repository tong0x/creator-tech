import Parser from 'rss-parser';
import axios from 'axios';
import type { IngestedItem } from '../types/index.js';

export class NewsIntegration {
  private parser: Parser;

  // Curated RSS feeds for crypto/market news
  private readonly feeds = {
    crypto: [
      { name: 'CoinDesk', url: 'https://www.coindesk.com/arc/outboundfeeds/rss/' },
      { name: 'Cointelegraph', url: 'https://cointelegraph.com/rss' },
      { name: 'The Block', url: 'https://www.theblock.co/rss.xml' },
    ],
    markets: [
      { name: 'Bloomberg Markets', url: 'https://feeds.bloomberg.com/markets/news.rss' },
      { name: 'Reuters Business', url: 'https://www.reutersagency.com/feed/?best-topics=business-finance' },
    ],
    tech: [
      { name: 'TechCrunch', url: 'https://techcrunch.com/feed/' },
      { name: 'Hacker News', url: 'https://hnrss.org/frontpage' },
    ],
  };

  constructor() {
    this.parser = new Parser({
      timeout: 10000,
    });
  }

  async getCryptoNews(since?: Date, limit: number = 20): Promise<IngestedItem[]> {
    return this.getNewsFromFeeds(this.feeds.crypto, since, limit);
  }

  async getMarketNews(since?: Date, limit: number = 20): Promise<IngestedItem[]> {
    return this.getNewsFromFeeds(this.feeds.markets, since, limit);
  }

  async getTechNews(since?: Date, limit: number = 20): Promise<IngestedItem[]> {
    return this.getNewsFromFeeds(this.feeds.tech, since, limit);
  }

  async getAllNews(since?: Date, limit: number = 30): Promise<IngestedItem[]> {
    const allFeeds = [
      ...this.feeds.crypto,
      ...this.feeds.markets,
      ...this.feeds.tech,
    ];

    return this.getNewsFromFeeds(allFeeds, since, limit);
  }

  private async getNewsFromFeeds(
    feeds: { name: string; url: string }[],
    since?: Date,
    limit: number = 20
  ): Promise<IngestedItem[]> {
    const items: IngestedItem[] = [];

    for (const feed of feeds) {
      try {
        const parsed = await this.parser.parseURL(feed.url);

        for (const item of parsed.items || []) {
          const pubDate = item.pubDate ? new Date(item.pubDate) : new Date();

          if (since && pubDate < since) continue;

          items.push({
            id: `news-${feed.name}-${item.guid || item.link}`,
            source: 'news' as any,
            type: 'news',
            title: item.title || 'No title',
            content: item.contentSnippet || item.content || '',
            sender: feed.name,
            url: item.link,
            timestamp: pubDate,
            rawData: item,
            metadata: {
              feedName: feed.name,
              categories: item.categories,
            },
          });
        }
      } catch (error) {
        console.error(`Failed to fetch RSS feed ${feed.name}:`, error);
      }
    }

    // Sort by date, newest first
    items.sort((a, b) => b.timestamp.getTime() - a.timestamp.getTime());

    return items.slice(0, limit);
  }

  async searchNews(keywords: string[], since?: Date): Promise<IngestedItem[]> {
    const allNews = await this.getAllNews(since, 100);

    const keywordsLower = keywords.map(k => k.toLowerCase());

    return allNews.filter(item => {
      const text = `${item.title} ${item.content}`.toLowerCase();
      return keywordsLower.some(keyword => text.includes(keyword));
    });
  }

  // Fear & Greed Index (crypto sentiment)
  async getCryptoFearGreedIndex(): Promise<{ value: number; classification: string }> {
    try {
      const response = await axios.get('https://api.alternative.me/fng/');
      const data = response.data.data[0];

      return {
        value: parseInt(data.value),
        classification: data.value_classification,
      };
    } catch (error) {
      console.error('Fear & Greed fetch error:', error);
      return { value: 50, classification: 'Neutral' };
    }
  }
}

export const newsIntegration = new NewsIntegration();
