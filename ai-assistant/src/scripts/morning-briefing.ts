/**
 * Manual trigger for morning briefing
 * Run with: npm run morning-briefing
 */

import { briefingService } from '../services/briefing.js';
import { marketIntegration } from '../integrations/index.js';

async function main() {
  console.log('Generating morning briefing...');
  console.log('==============================');

  // Initialize market data
  await marketIntegration.initializeWithHistoricalData();

  // Generate and send briefing
  await briefingService.sendMorningBriefing();

  console.log('==============================');
  console.log('Morning briefing sent!');

  process.exit(0);
}

main().catch(error => {
  console.error('Error:', error);
  process.exit(1);
});
