import { ADFFConfig, ADFFClient, ParsedCommand, ExecutionContext } from './types.js';
import { loadCommands } from './parser/commandParser.js';
import { executeCode } from './interpreter/index.js';

const FLUXER_API = 'https://api.fluxer.app';
const FLUXER_GATEWAY = 'wss://gateway.fluxer.app/?v=1&encoding=json';

interface GatewayMessage {
  op: number;
  d: any;
  s?: number;
  t?: string;
}

interface HeartbeatInfo {
  interval: number;
  lastSequence: number | null;
}

export function createADFFClient(config: ADFFConfig): ADFFClient {
  let ws: WebSocket | null = null;
  let heartbeatTimer: Timer | null = null;
  let commands = new Map<string, ParsedCommand>();
  let heartbeatInfo: HeartbeatInfo | null = null;
  let sessionId: string | null = null;
  let reconnectAttempts = 0;
  const maxReconnectAttempts = 5;

  // REST API helper using native fetch
  async function apiRequest<T>(method: string, path: string, body?: any): Promise<T> {
    const url = `${FLUXER_API}${path}`;
    const headers: Record<string, string> = {
      'Authorization': `Bot ${config.token}`,
      'Content-Type': 'application/json',
      'User-Agent': 'ADFF/1.0'
    };

    const options: RequestInit = {
      method,
      headers
    };

    if (body) {
      options.body = JSON.stringify(body);
    }

    const response = await fetch(url, options);
    
    if (!response.ok) {
      const error = await response.text();
      throw new Error(`API Error ${response.status}: ${error}`);
    }

    if (response.status === 204) {
      return {} as T;
    }

    return response.json();
  }

  // Send message to channel
  async function sendMessage(channelId: string, content?: string, embed?: any): Promise<void> {
    const body: any = {};
    if (content) body.content = content;
    if (embed) body.embeds = [embed];
    
    await apiRequest('POST', `/channels/${channelId}/messages`, body);
  }

  // Send gateway message
  function send(op: number, data: any): void {
    if (ws && ws.readyState === WebSocket.OPEN) {
      ws.send(JSON.stringify({ op, d: data }));
    }
  }

  // Start heartbeat
  function startHeartbeat(interval: number): void {
    if (heartbeatTimer) {
      clearInterval(heartbeatTimer);
    }
    
    heartbeatTimer = setInterval(() => {
      send(1, heartbeatInfo?.lastSequence ?? null);
      if (config.debug) {
        console.log('[ADFF] Heartbeat sent');
      }
    }, interval);
  }

  // Identify with gateway
  function identify(): void {
    send(2, {
      token: config.token,
      properties: {
        os: process.platform,
        browser: 'ADFF',
        device: 'ADFF'
      },
      intents: 513 // Guilds + GuildMessages + MessageContent
    });
  }

  // Resume session
  function resume(): void {
    if (sessionId && heartbeatInfo?.lastSequence) {
      send(6, {
        token: config.token,
        session_id: sessionId,
        seq: heartbeatInfo.lastSequence
      });
    }
  }

  // Handle gateway message
  async function handleMessage(data: GatewayMessage): Promise<void> {
    const { op, d, s, t } = data;

    // Update sequence number
    if (s !== null && s !== undefined) {
      if (heartbeatInfo) {
        heartbeatInfo.lastSequence = s;
      }
    }

    switch (op) {
      case 10: // Hello
        heartbeatInfo = {
          interval: d.heartbeat_interval,
          lastSequence: null
        };
        startHeartbeat(d.heartbeat_interval);
        
        // Resume or identify
        if (sessionId) {
          resume();
        } else {
          identify();
        }
        break;

      case 11: // Heartbeat ACK
        if (config.debug) {
          console.log('[ADFF] Heartbeat ACK received');
        }
        break;

      case 0: // Dispatch
        await handleDispatch(t, d);
        break;

      case 7: // Reconnect
        console.log('[ADFF] Gateway requested reconnect');
        reconnect();
        break;

      case 9: // Invalid Session
        console.log('[ADFF] Invalid session, re-identifying...');
        sessionId = null;
        setTimeout(() => identify(), 1000);
        break;
    }
  }

  // Handle dispatch events
  async function handleDispatch(event: string | undefined, data: any): Promise<void> {
    if (!event) return;

    switch (event) {
      case 'READY':
        sessionId = data.session_id;
        console.log('[ADFF] Bot is online and ready!');
        reconnectAttempts = 0;
        break;

      case 'MESSAGE_CREATE':
        await handleMessageCreate(data);
        break;

      case 'GUILD_CREATE':
        if (config.debug) {
          console.log(`[ADFF] Joined guild: ${data.name}`);
        }
        break;
    }
  }

  // Handle message create event
  async function handleMessageCreate(message: any): Promise<void> {
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
        await sendMessage(message.channel_id, result.content || undefined, result.embed);
      } else if (result.content) {
        await sendMessage(message.channel_id, result.content);
      }
    } catch (error) {
      console.error(`[ADFF] Error executing command ${command.name}:`, error);
    }
  }

  // Connect to gateway
  async function connect(): Promise<void> {
    return new Promise((resolve, reject) => {
      try {
        ws = new WebSocket(FLUXER_GATEWAY);

        ws.onopen = () => {
          console.log('[ADFF] WebSocket connected');
          resolve();
        };

        ws.onmessage = (event) => {
          try {
            const data = JSON.parse(event.data as string);
            handleMessage(data);
          } catch (error) {
            console.error('[ADFF] Error parsing message:', error);
          }
        };

        ws.onerror = (error) => {
          console.error('[ADFF] WebSocket error:', error);
        };

        ws.onclose = (event) => {
          console.log(`[ADFF] WebSocket closed: ${event.code} ${event.reason}`);
          
          if (heartbeatTimer) {
            clearInterval(heartbeatTimer);
            heartbeatTimer = null;
          }

          // Attempt reconnect if not intentional close
          if (event.code !== 1000 && reconnectAttempts < maxReconnectAttempts) {
            reconnectAttempts++;
            console.log(`[ADFF] Reconnecting (attempt ${reconnectAttempts}/${maxReconnectAttempts})...`);
            setTimeout(() => connect(), 5000 * reconnectAttempts);
          }
        };
      } catch (error) {
        reject(error);
      }
    });
  }

  // Reconnect
  function reconnect(): void {
    if (ws) {
      ws.close();
      ws = null;
    }
    if (heartbeatTimer) {
      clearInterval(heartbeatTimer);
      heartbeatTimer = null;
    }
    setTimeout(() => connect(), 1000);
  }

  async function start(): Promise<void> {
    if (!config.token) {
      throw new Error('[ADFF] Token is required! Set it in your config.');
    }

    const commandsPath = config.commandsPath || './commands/';
    
    // Load commands
    commands = await loadCommands(commandsPath);

    console.log('[ADFF] Connecting to Fluxer...');
    await connect();
  }

  function stop(): void {
    if (heartbeatTimer) {
      clearInterval(heartbeatTimer);
      heartbeatTimer = null;
    }
    if (ws) {
      ws.close(1000, 'Bot shutting down');
      ws = null;
    }
    console.log('[ADFF] Bot stopped');
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
