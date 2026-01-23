import { LinearClient } from '@linear/sdk';
import { config } from '../config/index.js';
import type { IngestedItem } from '../types/index.js';

export class LinearIntegration {
  private client: LinearClient | null = null;

  constructor() {
    if (config.LINEAR_API_KEY) {
      this.client = new LinearClient({ apiKey: config.LINEAR_API_KEY });
    }
  }

  isEnabled(): boolean {
    return this.client !== null;
  }

  async getAssignedIssues(): Promise<IngestedItem[]> {
    if (!this.client) return [];

    try {
      const me = await this.client.viewer;
      const issues = await me.assignedIssues({
        filter: {
          state: { type: { nin: ['completed', 'canceled'] } },
        },
      });

      const items: IngestedItem[] = [];

      for (const issue of issues.nodes) {
        const state = await issue.state;
        items.push({
          id: `linear-${issue.id}`,
          source: 'linear',
          type: 'assignment',
          title: issue.title,
          content: issue.description || '',
          sender: (await issue.creator)?.name,
          url: issue.url,
          timestamp: new Date(issue.updatedAt),
          rawData: issue,
          metadata: {
            identifier: issue.identifier,
            priority: issue.priority,
            state: state?.name,
          },
        });
      }

      return items;
    } catch (error) {
      console.error('Linear fetch error:', error);
      return [];
    }
  }

  async getRecentActivity(since: Date): Promise<IngestedItem[]> {
    if (!this.client) return [];

    try {
      const me = await this.client.viewer;

      // Get issues updated since the given time
      const issues = await me.assignedIssues({
        filter: {
          updatedAt: { gte: since },
        },
      });

      const items: IngestedItem[] = [];

      for (const issue of issues.nodes) {
        // Get comments on the issue
        const comments = await issue.comments();

        for (const comment of comments.nodes) {
          if (new Date(comment.createdAt) > since) {
            const author = await comment.user;

            // Skip own comments
            if (author?.id === me.id) continue;

            items.push({
              id: `linear-comment-${comment.id}`,
              source: 'linear',
              type: 'mention',
              title: `Comment on ${issue.identifier}: ${issue.title}`,
              content: comment.body,
              sender: author?.name,
              url: issue.url,
              timestamp: new Date(comment.createdAt),
              rawData: comment,
              metadata: {
                issueId: issue.id,
                issueIdentifier: issue.identifier,
              },
            });
          }
        }
      }

      return items;
    } catch (error) {
      console.error('Linear activity fetch error:', error);
      return [];
    }
  }

  async getHighPriorityIssues(): Promise<IngestedItem[]> {
    if (!this.client) return [];

    try {
      const me = await this.client.viewer;
      const issues = await me.assignedIssues({
        filter: {
          priority: { in: [1, 2] }, // Urgent and High
          state: { type: { nin: ['completed', 'canceled'] } },
        },
      });

      const items: IngestedItem[] = [];

      for (const issue of issues.nodes) {
        const state = await issue.state;
        items.push({
          id: `linear-priority-${issue.id}`,
          source: 'linear',
          type: 'assignment',
          title: `[P${issue.priority}] ${issue.title}`,
          content: issue.description || '',
          url: issue.url,
          timestamp: new Date(issue.updatedAt),
          rawData: issue,
          metadata: {
            identifier: issue.identifier,
            priority: issue.priority,
            state: state?.name,
          },
        });
      }

      return items;
    } catch (error) {
      console.error('Linear priority fetch error:', error);
      return [];
    }
  }
}

export const linearIntegration = new LinearIntegration();
