import { google } from 'googleapis';
import { config } from '../config/index.js';
import type { CalendarEvent } from '../types/index.js';

export class CalendarIntegration {
  private calendar: ReturnType<typeof google.calendar> | null = null;

  constructor() {
    if (config.GOOGLE_CLIENT_ID && config.GOOGLE_CLIENT_SECRET && config.GOOGLE_REFRESH_TOKEN) {
      const oauth2Client = new google.auth.OAuth2(
        config.GOOGLE_CLIENT_ID,
        config.GOOGLE_CLIENT_SECRET
      );

      oauth2Client.setCredentials({
        refresh_token: config.GOOGLE_REFRESH_TOKEN,
      });

      this.calendar = google.calendar({ version: 'v3', auth: oauth2Client });
    }
  }

  isEnabled(): boolean {
    return this.calendar !== null;
  }

  async getTodayEvents(): Promise<CalendarEvent[]> {
    if (!this.calendar) return [];

    const now = new Date();
    const startOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const endOfDay = new Date(startOfDay.getTime() + 24 * 60 * 60 * 1000);

    return this.getEvents(startOfDay, endOfDay);
  }

  async getUpcomingEvents(hours: number = 24): Promise<CalendarEvent[]> {
    if (!this.calendar) return [];

    const now = new Date();
    const future = new Date(now.getTime() + hours * 60 * 60 * 1000);

    return this.getEvents(now, future);
  }

  async getEvents(startTime: Date, endTime: Date): Promise<CalendarEvent[]> {
    if (!this.calendar) return [];

    try {
      const response = await this.calendar.events.list({
        calendarId: 'primary',
        timeMin: startTime.toISOString(),
        timeMax: endTime.toISOString(),
        singleEvents: true,
        orderBy: 'startTime',
      });

      const events = response.data.items || [];

      return events.map(event => ({
        id: event.id || '',
        title: event.summary || 'No title',
        description: event.description,
        startTime: new Date(event.start?.dateTime || event.start?.date || ''),
        endTime: new Date(event.end?.dateTime || event.end?.date || ''),
        attendees: event.attendees?.map(a => a.email || '').filter(Boolean),
        location: event.location,
        isAllDay: !event.start?.dateTime,
      }));
    } catch (error) {
      console.error('Calendar fetch error:', error);
      return [];
    }
  }

  async getNextMeeting(): Promise<CalendarEvent | null> {
    const events = await this.getUpcomingEvents(8);
    return events[0] || null;
  }

  async getMeetingsWithPerson(email: string, days: number = 7): Promise<CalendarEvent[]> {
    if (!this.calendar) return [];

    const now = new Date();
    const future = new Date(now.getTime() + days * 24 * 60 * 60 * 1000);

    const events = await this.getEvents(now, future);

    return events.filter(event =>
      event.attendees?.some(attendee =>
        attendee.toLowerCase().includes(email.toLowerCase())
      )
    );
  }

  async getFreeBusyInfo(startTime: Date, endTime: Date): Promise<{ start: Date; end: Date }[]> {
    if (!this.calendar) return [];

    try {
      const response = await this.calendar.freebusy.query({
        requestBody: {
          timeMin: startTime.toISOString(),
          timeMax: endTime.toISOString(),
          items: [{ id: 'primary' }],
        },
      });

      const busy = response.data.calendars?.primary?.busy || [];

      return busy.map(slot => ({
        start: new Date(slot.start || ''),
        end: new Date(slot.end || ''),
      }));
    } catch (error) {
      console.error('Free/busy fetch error:', error);
      return [];
    }
  }

  async getEventReminders(minutesBefore: number = 15): Promise<CalendarEvent[]> {
    const events = await this.getUpcomingEvents(1);

    const now = new Date();
    const reminderWindow = new Date(now.getTime() + minutesBefore * 60 * 1000);

    return events.filter(event => {
      const eventStart = new Date(event.startTime);
      return eventStart > now && eventStart <= reminderWindow;
    });
  }
}

export const calendarIntegration = new CalendarIntegration();
