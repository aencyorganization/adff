// ============================================
// ADFF Configuration File
// ============================================
// Modify the values below to configure your bot

import { createADFFClient } from 'adff';

// Your bot token from Fluxer (required)
const TOKEN = 'YOUR_BOT_TOKEN_HERE';

// Command prefix (e.g., "!" for !ping)
const PREFIX = '!';

// Path to commands folder (default: ./commands/)
const COMMANDS_PATH = './commands/';

// ============================================
// Don't modify below this line
// ============================================

const bot = createADFFClient({
  token: TOKEN,
  prefix: PREFIX,
  commandsPath: COMMANDS_PATH,
  debug: true
});

bot.start().catch(console.error);

// Handle graceful shutdown
process.on('SIGINT', () => {
  console.log('\n[ADFF] Shutting down...');
  bot.stop();
  process.exit(0);
});
