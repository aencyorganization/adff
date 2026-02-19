// ADFF Types

export interface ADFFConfig {
  /** Bot token for Fluxer */
  token: string;
  /** Command prefix for text commands */
  prefix: string;
  /** Path to commands directory (default: ./commands/) */
  commandsPath?: string;
  /** Application ID (optional, will be fetched automatically) */
  applicationId?: string;
  /** Enable debug logging */
  debug?: boolean;
}

export interface ParsedCommand {
  /** Command name */
  name: string;
  /** Command aliases */
  aliases: string[];
  /** Raw code content after header */
  code: string;
  /** Source file path */
  filePath: string;
}

export interface ExecutionContext {
  /** Message content (without prefix and command) */
  args: string[];
  /** Full message content */
  messageContent: string;
  /** Channel ID */
  channelId: string;
  /** Guild ID (if in a server) */
  guildId?: string;
  /** Author ID */
  authorId: string;
  /** Author username */
  authorUsername: string;
  /** Raw message object */
  raw: any;
}

export interface EmbedData {
  title?: string;
  description?: string;
  color?: number;
}

export interface FunctionResult {
  /** Text content to send */
  content?: string;
  /** Embed data if any */
  embed?: EmbedData;
  /** Whether this result should be combined with others */
  combine?: boolean;
}

export type ADFFFunction = (
  args: string[],
  context: ExecutionContext,
  state: InterpreterState
) => Promise<FunctionResult | string | void>;

export interface InterpreterState {
  /** Current embed being built */
  embed: EmbedData;
  /** Accumulated content */
  content: string;
  /** Whether an embed has been started */
  hasEmbed: boolean;
}

export interface ADFFClient {
  /** Start the bot */
  start: () => Promise<void>;
  /** Stop the bot */
  stop: () => void;
  /** Reload commands from disk */
  reloadCommands: () => Promise<void>;
  /** Get loaded commands */
  getCommands: () => Map<string, ParsedCommand>;
}
