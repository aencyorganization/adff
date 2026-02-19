import { ParsedCommand } from '../types.js';
import { readFile, readdir } from 'fs/promises';
import { join, extname } from 'path';

/**
 * Remove comments from code (// style)
 */
function removeComments(code: string): string {
  const lines = code.split('\n');
  const cleanedLines = lines.map(line => {
    const commentIndex = line.indexOf('//');
    if (commentIndex === -1) return line;
    // Check if // is inside a function argument (between [ and ])
    let bracketDepth = 0;
    for (let i = 0; i < commentIndex; i++) {
      if (line[i] === '[') bracketDepth++;
      if (line[i] === ']') bracketDepth--;
    }
    if (bracketDepth > 0) return line; // Inside a function, keep the line
    return line.substring(0, commentIndex);
  });
  return cleanedLines.join('\n');
}

/**
 * Parse command header (name and aliases)
 */
function parseHeader(code: string): { name: string | null; aliases: string[]; codeStart: number } {
  const lines = code.split('\n');
  let name: string | null = null;
  let aliases: string[] = [];
  let codeStart = 0;

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i].trim();
    
    // Parse $name[...]
    const nameMatch = line.match(/^\$name\[([^\]]+)\]/);
    if (nameMatch) {
      name = nameMatch[1].trim().toLowerCase();
      codeStart = i + 1;
      continue;
    }

    // Parse $aliases[...]
    const aliasesMatch = line.match(/^\$aliases\[([^\]]+)\]/);
    if (aliasesMatch) {
      aliases = aliasesMatch[1].split(';').map(a => a.trim().toLowerCase()).filter(Boolean);
      codeStart = i + 1;
      continue;
    }

    // If we found a name and hit non-header content, stop
    if (name && !line.startsWith('$name[') && !line.startsWith('$aliases[') && line.length > 0) {
      break;
    }
  }

  return { name, aliases, codeStart };
}

/**
 * Parse a single command file
 */
export async function parseCommandFile(filePath: string): Promise<ParsedCommand | null> {
  try {
    const rawContent = await readFile(filePath, 'utf-8');
    const content = removeComments(rawContent);
    
    const { name, aliases, codeStart } = parseHeader(content);
    
    if (!name) {
      console.warn(`[ADFF] Command file ${filePath} has no $name declaration, skipping`);
      return null;
    }

    // Get code after header
    const lines = content.split('\n');
    const codeLines = lines.slice(codeStart);
    const code = codeLines.join('\n').trim();

    return {
      name,
      aliases,
      code,
      filePath
    };
  } catch (error) {
    console.error(`[ADFF] Error parsing command file ${filePath}:`, error);
    return null;
  }
}

/**
 * Load all commands from a directory
 */
export async function loadCommands(commandsPath: string): Promise<Map<string, ParsedCommand>> {
  const commands = new Map<string, ParsedCommand>();
  
  try {
    const files = await readdir(commandsPath);
    const jsFiles = files.filter(f => extname(f) === '.js');
    
    for (const file of jsFiles) {
      const filePath = join(commandsPath, file);
      const command = await parseCommandFile(filePath);
      
      if (command) {
        // Store by name
        commands.set(command.name, command);
        
        // Store by aliases
        for (const alias of command.aliases) {
          commands.set(alias, command);
        }
        
        console.log(`[ADFF] Loaded command: ${command.name}${command.aliases.length ? ` (aliases: ${command.aliases.join(', ')})` : ''}`);
      }
    }
    
    console.log(`[ADFF] Loaded ${commands.size} command entries from ${jsFiles.length} files`);
  } catch (error) {
    console.error(`[ADFF] Error loading commands from ${commandsPath}:`, error);
  }
  
  return commands;
}
