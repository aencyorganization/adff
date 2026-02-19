import { REST } from '@discordjs/rest';
import { WebSocketManager } from '@discordjs/ws';
import { Client, GatewayIntentBits } from '@discordjs/core';
import { ADFFConfig, ADFFClient, ParsedCommand, ExecutionContext } from './types.js';
import { loadCommands } from './parser/commandParser.js';
import { executeCode } from './interpreter/index.js';

const DEFAULT_GRAY_COLOR = 0x808080;

export function createADFFClient(config: ADFFConfig): ADFFClient {
  let client: Client | null = null;
  let gateway: WebSocketManager | null = null;
  let commands = new Map<string, ParsedCommand>();

  async function start(): Promise<void> {
    if (!config.token) {
      throw new Error('[ADFF] Token is required! Set it in your config.');
    }

    const commandsPath = config.commandsPath || './commands/';
    
    // Load commands
    commands = await loadCommands(commandsPath);

    // Configure REST for Fluxer
    const rest = new REST({
      version: '1',
      api: 'https://api.fluxer.app',
      cdn: 'https://cdn.fluxer.app'
    }).setToken(config.token);

    // Configure WebSocket for Fluxer Gateway
    gateway = new WebSocketManager({
      token: config.token,
      intents: GatewayIntentBits.Guilds | GatewayIntentBits.GuildMessages | GatewayIntentBits.MessageContent,
      rest
    });

    // Create client
    client = new Client({ rest, gateway });

    // Ready event
    client.once('ready', () => {
      console.log('[ADFF] Bot is online and ready!');
    });

    // Message handler
    client.on('messageCreate', async ({ data: message }) => {
      // Ignore bot messages
      if (message.author?.bot) return;

      const content = message.content || '';
      
      // Check for prefix
      if (!content.startsWith(config.prefix)) return;

      // Parse command and args
      const withoutPrefix = content.slice(config.prefix.length).trim();
      const args = withoutPrefix.split(/\s+/);
      const commandName = args.shift()?.toLowerCase();

      if (!commandName) return;

      // Find command
      const command = commands.get(commandName);
      if (!command) return;

      if (config.debug) {
        console.log(`[ADFF] Executing command: ${command.name}`);
      }

      // Create execution context
      const context: ExecutionContext = {
        args,
        messageContent: withoutPrefix.slice(commandName.length).trim(),
        channelId: message.channel_id,
        guildId: message.guild_id,
        authorId: message.author?.id || '',
        authorUsername: message.author?.username || 'Unknown',
        raw: message
      };

      try {
        // Execute the command code
        const result = await executeCode(command.code, context);

        // Send response
        if (result.embed) {
          await rest.post(`/channels/${message.channel_id}/messages`, {
            body: {
              content: result.content || undefined,
              embeds: [result.embed]
            }
          });
        } else if (result.content) {
          await rest.post(`/channels/${message.channel_id}/messages`, {
            body: {
              content: result.content
            }
          });
        }
      } catch (error) {
        console.error(`[ADFF] Error executing command ${command.name}:`, error);
      }
    });

    // Connect
    console.log('[ADFF] Connecting to Fluxer...');
    await gateway.connect();
  }

  function stop(): void {
    if (gateway) {
      gateway.destroy();
      console.log('[ADFF] Bot stopped');
    }
  }

  async function reloadCommands(): Promise<void> {
    const commandsPath = config.commandsPath || './commands/';
    commands = await loadCommands(commandsPath);
  }

  function getCommands(): Map<string, ParsedCommand> {
    return new Map(commands);
  }

  return {
    start,
    stop,
    reloadCommands,
    getCommands
  };
}

// Re-export types and utilities
export * from './types.js';
export { loadCommands, parseCommandFile } from './parser/commandParser.js';
export { executeCode, processText, registerFunction, getFunction } from './interpreter/index.js';
