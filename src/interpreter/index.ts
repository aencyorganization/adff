import { ExecutionContext, InterpreterState, FunctionResult, ADFFFunction } from '../types.js';

// Built-in functions registry
const functions = new Map<string, ADFFFunction>();

/**
 * Register a function
 */
export function registerFunction(name: string, fn: ADFFFunction): void {
  functions.set(name.toLowerCase(), fn);
}

/**
 * Get a registered function
 */
export function getFunction(name: string): ADFFFunction | undefined {
  return functions.get(name.toLowerCase());
}

// ============================================
// BUILT-IN FUNCTIONS
// ============================================

/**
 * $randomText[arg1;arg2;...]
 * Returns a random argument
 */
registerFunction('randomText', async (args, context, state) => {
  if (args.length < 2) {
    console.warn('[ADFF] $randomText requires at least 2 arguments');
    return args[0] || '';
  }
  const randomIndex = Math.floor(Math.random() * args.length);
  return args[randomIndex];
});

/**
 * $title[text]
 * Sets the embed title
 */
registerFunction('title', async (args, context, state) => {
  if (args.length < 1 || !args[0]) {
    console.warn('[ADFF] $title requires 1 argument');
    return '';
  }
  state.embed.title = args[0];
  state.hasEmbed = true;
  return '';
});

/**
 * $description[text]
 * Sets the embed description
 */
registerFunction('description', async (args, context, state) => {
  if (args.length < 1 || !args[0]) {
    console.warn('[ADFF] $description requires 1 argument');
    return '';
  }
  state.embed.description = args[0];
  state.hasEmbed = true;
  return '';
});

/**
 * $color[hex1;hex2;...]
 * Sets the embed color (random if multiple)
 */
registerFunction('color', async (args, context, state) => {
  if (args.length < 1 || !args[0]) {
    console.warn('[ADFF] $color requires at least 1 argument');
    return '';
  }
  
  const colors = args.filter(c => c && c.startsWith('#'));
  if (colors.length === 0) {
    console.warn('[ADFF] $color requires valid hex colors starting with #');
    return '';
  }
  
  const selectedColor = colors.length === 1 
    ? colors[0] 
    : colors[Math.floor(Math.random() * colors.length)];
  
  // Convert hex to number
  state.embed.color = parseInt(selectedColor.replace('#', ''), 16);
  return '';
});

// ============================================
// INTERPRETER
// ============================================

/**
 * Parse function arguments from text like [arg1;arg2;arg3]
 * Handles nested functions properly
 */
function parseFunctionArgs(text: string): string[] {
  const args: string[] = [];
  let current = '';
  let depth = 0;
  
  for (let i = 0; i < text.length; i++) {
    const char = text[i];
    
    if (char === '[') {
      depth++;
      current += char;
    } else if (char === ']') {
      depth--;
      current += char;
    } else if (char === ';' && depth === 0) {
      args.push(current.trim());
      current = '';
    } else {
      current += char;
    }
  }
  
  if (current.trim()) {
    args.push(current.trim());
  }
  
  return args;
}

/**
 * Find and execute a function in text
 * Returns { result, remainingText }
 */
async function executeFunction(
  text: string, 
  context: ExecutionContext, 
  state: InterpreterState
): Promise<{ result: string; remaining: string }> {
  // Find $functionName[
  const match = text.match(/\$([a-zA-Z_][a-zA-Z0-9_]*)\[/);
  
  if (!match) {
    return { result: text, remaining: '' };
  }
  
  const functionName = match[1];
  const startIndex = match.index!;
  const bracketStart = startIndex + match[0].length - 1;
  
  // Find matching closing bracket
  let depth = 1;
  let endIndex = bracketStart + 1;
  
  while (depth > 0 && endIndex < text.length) {
    if (text[endIndex] === '[') depth++;
    if (text[endIndex] === ']') depth--;
    endIndex++;
  }
  
  const argsText = text.substring(bracketStart + 1, endIndex - 1);
  const beforeFunction = text.substring(0, startIndex);
  const afterFunction = text.substring(endIndex);
  
  // Parse arguments (they might contain nested functions)
  const rawArgs = parseFunctionArgs(argsText);
  
  // Recursively process arguments (for nested functions)
  const processedArgs: string[] = [];
  for (const arg of rawArgs) {
    const processed = await processText(arg, context, state);
    processedArgs.push(processed);
  }
  
  // Execute the function
  const fn = getFunction(functionName);
  let result: string;
  
  if (fn) {
    const fnResult = await fn(processedArgs, context, state);
    if (typeof fnResult === 'string') {
      result = fnResult;
    } else if (fnResult && typeof fnResult === 'object') {
      result = fnResult.content || '';
    } else {
      result = '';
    }
  } else {
    console.warn(`[ADFF] Unknown function: $${functionName}`);
    result = '';
  }
  
  return {
    result: beforeFunction + result,
    remaining: afterFunction
  };
}

/**
 * Process text and execute all functions
 */
export async function processText(
  text: string, 
  context: ExecutionContext, 
  state: InterpreterState
): Promise<string> {
  let result = text;
  let iterations = 0;
  const maxIterations = 100; // Prevent infinite loops
  
  while (result.includes('$') && iterations < maxIterations) {
    const { result: newResult, remaining } = await executeFunction(result, context, state);
    result = newResult + remaining;
    iterations++;
  }
  
  return result;
}

/**
 * Create a new interpreter state
 */
export function createState(): InterpreterState {
  return {
    embed: {
      color: 0x808080 // Default gray
    },
    content: '',
    hasEmbed: false
  };
}

/**
 * Execute a command's code
 */
export async function executeCode(
  code: string, 
  context: ExecutionContext
): Promise<{ content: string; embed: InterpreterState['embed'] | null }> {
  const state = createState();
  
  // Process the code
  const processedContent = await processText(code, context, state);
  
  // Clean up content
  const content = processedContent.trim();
  
  // Return result
  return {
    content: state.hasEmbed ? '' : content,
    embed: state.hasEmbed ? state.embed : null
  };
}
