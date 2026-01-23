import axios from 'axios';
import { RSI, MACD, EMA } from 'technicalindicators';
import type { MarketData, MarketAlert, EconomicEvent } from '../types/index.js';

export class MarketIntegration {
  private priceHistory: Map<string, number[]> = new Map();
  private readonly historyLength = 100;

  async getBTCData(): Promise<MarketData> {
    try {
      // Fetch from CoinGecko (free, no API key required)
      const response = await axios.get(
        'https://api.coingecko.com/api/v3/simple/price',
        {
          params: {
            ids: 'bitcoin',
            vs_currencies: 'usd',
            include_24hr_change: true,
            include_24hr_vol: true,
          },
        }
      );

      const btc = response.data.bitcoin;

      // Store price for indicators
      this.addPriceToHistory('BTC', btc.usd);

      // Calculate indicators
      const indicators = this.calculateIndicators('BTC');

      return {
        symbol: 'BTC',
        price: btc.usd,
        change24h: btc.usd_24h_change,
        volume24h: btc.usd_24h_vol,
        timestamp: new Date(),
        indicators,
      };
    } catch (error) {
      console.error('BTC data fetch error:', error);
      throw error;
    }
  }

  async getOHLCData(symbol: string = 'bitcoin', days: number = 30): Promise<number[][]> {
    try {
      const response = await axios.get(
        `https://api.coingecko.com/api/v3/coins/${symbol}/ohlc`,
        {
          params: {
            vs_currency: 'usd',
            days,
          },
        }
      );

      return response.data; // [timestamp, open, high, low, close]
    } catch (error) {
      console.error('OHLC data fetch error:', error);
      return [];
    }
  }

  async initializeWithHistoricalData(): Promise<void> {
    try {
      const ohlc = await this.getOHLCData('bitcoin', 14);
      const closes = ohlc.map(candle => candle[4]); // Close prices

      this.priceHistory.set('BTC', closes.slice(-this.historyLength));
      console.log(`Initialized BTC price history with ${closes.length} data points`);
    } catch (error) {
      console.error('Failed to initialize historical data:', error);
    }
  }

  private addPriceToHistory(symbol: string, price: number): void {
    const history = this.priceHistory.get(symbol) || [];
    history.push(price);

    if (history.length > this.historyLength) {
      history.shift();
    }

    this.priceHistory.set(symbol, history);
  }

  private calculateIndicators(symbol: string): MarketData['indicators'] {
    const prices = this.priceHistory.get(symbol) || [];

    if (prices.length < 14) {
      return undefined;
    }

    // RSI (14 period)
    const rsiValues = RSI.calculate({
      values: prices,
      period: 14,
    });
    const rsi = rsiValues[rsiValues.length - 1];

    // MACD
    const macdValues = MACD.calculate({
      values: prices,
      fastPeriod: 12,
      slowPeriod: 26,
      signalPeriod: 9,
      SimpleMAOscillator: false,
      SimpleMASignal: false,
    });
    const macd = macdValues[macdValues.length - 1];

    // EMA (short: 9, long: 21)
    const emaShort = EMA.calculate({ values: prices, period: 9 });
    const emaLong = EMA.calculate({ values: prices, period: 21 });

    // Momentum (price change over last 10 periods)
    const momentum = prices.length >= 10
      ? ((prices[prices.length - 1] - prices[prices.length - 10]) / prices[prices.length - 10]) * 100
      : undefined;

    return {
      rsi,
      macd: macd ? {
        value: macd.MACD || 0,
        signal: macd.signal || 0,
        histogram: macd.histogram || 0,
      } : undefined,
      ema: emaShort.length && emaLong.length ? {
        short: emaShort[emaShort.length - 1],
        long: emaLong[emaLong.length - 1],
      } : undefined,
      momentum,
    };
  }

  checkMomentumAlert(data: MarketData, threshold: number = 5): MarketAlert | null {
    if (!data.indicators?.momentum) return null;

    const momentum = data.indicators.momentum;
    const absChange = Math.abs(data.change24h);

    // Strong momentum conditions
    const hasStrongMomentum =
      Math.abs(momentum) > threshold ||
      absChange > threshold ||
      (data.indicators.rsi && (data.indicators.rsi > 70 || data.indicators.rsi < 30));

    if (!hasStrongMomentum) return null;

    let alertType: MarketAlert['alertType'] = 'momentum';
    let message = '';

    if (data.indicators.rsi) {
      if (data.indicators.rsi > 70) {
        message = `BTC RSI at ${data.indicators.rsi.toFixed(1)} - Overbought territory`;
      } else if (data.indicators.rsi < 30) {
        message = `BTC RSI at ${data.indicators.rsi.toFixed(1)} - Oversold territory`;
      }
    }

    if (Math.abs(momentum) > threshold) {
      const direction = momentum > 0 ? 'bullish' : 'bearish';
      message = `BTC showing strong ${direction} momentum: ${momentum.toFixed(2)}% move`;
      alertType = 'trend_change';
    }

    if (absChange > 5) {
      const direction = data.change24h > 0 ? 'up' : 'down';
      message = `BTC ${direction} ${absChange.toFixed(2)}% in 24h - Major move detected`;
    }

    return {
      symbol: data.symbol,
      alertType,
      message,
      data,
      timestamp: new Date(),
    };
  }

  async getEconomicCalendar(): Promise<EconomicEvent[]> {
    // Using a free economic calendar API
    // In production, you might want to use Trading Economics, Investing.com, or similar
    try {
      // Fallback: Return known scheduled events (Fed meetings, etc.)
      return this.getKnownEconomicEvents();
    } catch (error) {
      console.error('Economic calendar fetch error:', error);
      return this.getKnownEconomicEvents();
    }
  }

  private getKnownEconomicEvents(): EconomicEvent[] {
    // Fed FOMC meetings 2024-2025 (update this periodically)
    const fomcDates = [
      '2025-01-28', '2025-01-29',
      '2025-03-18', '2025-03-19',
      '2025-05-06', '2025-05-07',
      '2025-06-17', '2025-06-18',
      '2025-07-29', '2025-07-30',
      '2025-09-16', '2025-09-17',
      '2025-11-04', '2025-11-05',
      '2025-12-16', '2025-12-17',
    ];

    const now = new Date();
    const twoWeeksFromNow = new Date(now.getTime() + 14 * 24 * 60 * 60 * 1000);

    const events: EconomicEvent[] = [];

    // Add upcoming FOMC meetings
    for (let i = 0; i < fomcDates.length; i += 2) {
      const meetingStart = new Date(fomcDates[i]);
      const meetingEnd = new Date(fomcDates[i + 1]);

      if (meetingEnd >= now && meetingStart <= twoWeeksFromNow) {
        events.push({
          id: `fomc-${fomcDates[i]}`,
          title: 'FOMC Meeting / Interest Rate Decision',
          date: meetingEnd, // Decision usually on day 2
          importance: 'high',
          country: 'US',
        });
      }
    }

    // Add other regular events
    const regularEvents = [
      { dayOfWeek: 4, title: 'Initial Jobless Claims', importance: 'medium' as const },
      { dayOfMonth: 1, title: 'ISM Manufacturing PMI', importance: 'high' as const },
    ];

    // Find next occurrence of each regular event
    for (const event of regularEvents) {
      const nextDate = new Date(now);

      if (event.dayOfWeek !== undefined) {
        // Weekly event
        const daysUntil = (event.dayOfWeek - now.getDay() + 7) % 7;
        nextDate.setDate(now.getDate() + daysUntil);
      } else if (event.dayOfMonth !== undefined) {
        // Monthly event
        nextDate.setDate(event.dayOfMonth);
        if (nextDate < now) {
          nextDate.setMonth(nextDate.getMonth() + 1);
        }
      }

      if (nextDate <= twoWeeksFromNow) {
        events.push({
          id: `regular-${event.title}-${nextDate.toISOString()}`,
          title: event.title,
          date: nextDate,
          importance: event.importance,
          country: 'US',
        });
      }
    }

    return events.sort((a, b) => a.date.getTime() - b.date.getTime());
  }
}

export const marketIntegration = new MarketIntegration();
