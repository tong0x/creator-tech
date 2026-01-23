import { Octokit } from '@octokit/rest';
import { config } from '../config/index.js';
import type { IngestedItem } from '../types/index.js';

export class GitHubIntegration {
  private client: Octokit | null = null;

  constructor() {
    if (config.GITHUB_TOKEN) {
      this.client = new Octokit({ auth: config.GITHUB_TOKEN });
    }
  }

  isEnabled(): boolean {
    return this.client !== null;
  }

  async getNotifications(since: Date): Promise<IngestedItem[]> {
    if (!this.client) return [];

    try {
      const { data: notifications } = await this.client.activity.listNotificationsForAuthenticatedUser({
        since: since.toISOString(),
        all: false,
      });

      return notifications.map(n => ({
        id: `github-${n.id}`,
        source: 'github' as const,
        type: this.mapNotificationType(n.reason),
        title: n.subject.title,
        content: `${n.reason}: ${n.subject.title} in ${n.repository.full_name}`,
        sender: n.repository.full_name,
        url: n.subject.url?.replace('api.github.com/repos', 'github.com').replace('/pulls/', '/pull/'),
        timestamp: new Date(n.updated_at),
        rawData: n,
        metadata: {
          repo: n.repository.full_name,
          type: n.subject.type,
          reason: n.reason,
        },
      }));
    } catch (error) {
      console.error('GitHub fetch error:', error);
      return [];
    }
  }

  async getPRsNeedingReview(repos: string[]): Promise<IngestedItem[]> {
    if (!this.client) return [];

    const items: IngestedItem[] = [];

    for (const repo of repos) {
      try {
        const [owner, name] = repo.split('/');
        const { data: prs } = await this.client.pulls.list({
          owner,
          repo: name,
          state: 'open',
        });

        // Get PRs where user is requested reviewer
        const { data: user } = await this.client.users.getAuthenticated();

        for (const pr of prs) {
          const isReviewRequested = pr.requested_reviewers?.some(r => r.login === user.login);

          if (isReviewRequested) {
            items.push({
              id: `github-pr-${pr.id}`,
              source: 'github',
              type: 'review_request',
              title: `Review requested: ${pr.title}`,
              content: pr.body || '',
              sender: pr.user?.login,
              url: pr.html_url,
              timestamp: new Date(pr.updated_at),
              rawData: pr,
              metadata: {
                repo,
                prNumber: pr.number,
                additions: pr.additions,
                deletions: pr.deletions,
              },
            });
          }
        }
      } catch (error) {
        console.error(`GitHub PR fetch error for ${repo}:`, error);
      }
    }

    return items;
  }

  async getMentions(since: Date): Promise<IngestedItem[]> {
    if (!this.client) return [];

    try {
      const { data: user } = await this.client.users.getAuthenticated();

      const { data: issues } = await this.client.search.issuesAndPullRequests({
        q: `mentions:${user.login} updated:>=${since.toISOString().split('T')[0]}`,
        sort: 'updated',
        order: 'desc',
      });

      return issues.items.map(issue => ({
        id: `github-mention-${issue.id}`,
        source: 'github' as const,
        type: 'mention' as const,
        title: `Mentioned in: ${issue.title}`,
        content: issue.body || '',
        sender: issue.user?.login,
        url: issue.html_url,
        timestamp: new Date(issue.updated_at),
        rawData: issue,
      }));
    } catch (error) {
      console.error('GitHub mentions fetch error:', error);
      return [];
    }
  }

  private mapNotificationType(reason: string): 'mention' | 'review_request' | 'assignment' | 'direct_message' {
    switch (reason) {
      case 'mention':
      case 'team_mention':
        return 'mention';
      case 'review_requested':
        return 'review_request';
      case 'assign':
        return 'assignment';
      default:
        return 'direct_message';
    }
  }
}

export const githubIntegration = new GitHubIntegration();
