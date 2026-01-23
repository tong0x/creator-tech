import { TwitterApi } from 'twitter-api-v2';
import { config } from '../config/index.js';
import type { IngestedItem } from '../types/index.js';

export class TwitterIntegration {
  private client: TwitterApi | null = null;

  constructor() {
    if (config.X_API_KEY && config.X_API_SECRET && config.X_ACCESS_TOKEN && config.X_ACCESS_SECRET) {
      this.client = new TwitterApi({
        appKey: config.X_API_KEY,
        appSecret: config.X_API_SECRET,
        accessToken: config.X_ACCESS_TOKEN,
        accessSecret: config.X_ACCESS_SECRET,
      });
    }
  }

  isEnabled(): boolean {
    return this.client !== null;
  }

  async getMentions(since?: Date): Promise<IngestedItem[]> {
    if (!this.client) return [];

    try {
      const me = await this.client.v2.me();
      const mentions = await this.client.v2.userMentionTimeline(me.data.id, {
        max_results: 20,
        'tweet.fields': ['created_at', 'author_id', 'conversation_id'],
        expansions: ['author_id'],
        ...(since && { start_time: since.toISOString() }),
      });

      const items: IngestedItem[] = [];

      for (const tweet of mentions.data?.data || []) {
        const author = mentions.includes?.users?.find(u => u.id === tweet.author_id);

        items.push({
          id: `twitter-mention-${tweet.id}`,
          source: 'twitter',
          type: 'mention',
          title: `Mention from @${author?.username || 'unknown'}`,
          content: tweet.text,
          sender: author?.username,
          url: `https://twitter.com/${author?.username}/status/${tweet.id}`,
          timestamp: new Date(tweet.created_at || Date.now()),
          rawData: tweet,
          metadata: {
            authorId: tweet.author_id,
            conversationId: tweet.conversation_id,
          },
        });
      }

      return items;
    } catch (error) {
      console.error('Twitter mentions fetch error:', error);
      return [];
    }
  }

  async getDirectMessages(since?: Date): Promise<IngestedItem[]> {
    if (!this.client) return [];

    try {
      const dms = await this.client.v2.listDmEvents({
        max_results: 20,
        'dm_event.fields': ['created_at', 'sender_id', 'text'],
        expansions: ['sender_id'],
      });

      const items: IngestedItem[] = [];

      for (const dm of dms.data?.data || []) {
        const sender = dms.includes?.users?.find(u => u.id === dm.sender_id);
        const createdAt = new Date((dm as any).created_at || Date.now());

        if (since && createdAt < since) continue;

        items.push({
          id: `twitter-dm-${dm.id}`,
          source: 'twitter',
          type: 'direct_message',
          title: `DM from @${sender?.username || 'unknown'}`,
          content: dm.text || '',
          sender: sender?.username,
          url: 'https://twitter.com/messages',
          timestamp: createdAt,
          rawData: dm,
        });
      }

      return items;
    } catch (error) {
      console.error('Twitter DMs fetch error:', error);
      return [];
    }
  }

  async getTimelineFromAccounts(usernames: string[], since?: Date): Promise<IngestedItem[]> {
    if (!this.client) return [];

    const items: IngestedItem[] = [];

    for (const username of usernames) {
      try {
        const user = await this.client.v2.userByUsername(username);
        if (!user.data) continue;

        const tweets = await this.client.v2.userTimeline(user.data.id, {
          max_results: 10,
          'tweet.fields': ['created_at'],
          ...(since && { start_time: since.toISOString() }),
        });

        for (const tweet of tweets.data?.data || []) {
          items.push({
            id: `twitter-timeline-${tweet.id}`,
            source: 'twitter',
            type: 'news',
            title: `Tweet from @${username}`,
            content: tweet.text,
            sender: username,
            url: `https://twitter.com/${username}/status/${tweet.id}`,
            timestamp: new Date(tweet.created_at || Date.now()),
            rawData: tweet,
          });
        }
      } catch (error) {
        console.error(`Twitter timeline fetch error for @${username}:`, error);
      }
    }

    return items;
  }
}

export const twitterIntegration = new TwitterIntegration();
