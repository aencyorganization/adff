# ADFF - Application Designer For Fluxer

A simple, function-based wrapper for creating Fluxer/Discord bots without coding. Just use functions!

## Features

- 🚀 **No coding required** - Use simple functions like `$title[]`, `$description[]`, `$randomText[]`
- 📦 **Easy setup** - One command installation
- 🔧 **Bun-powered** - Fast and modern runtime
- 🎨 **Embed support** - Create beautiful embeds easily
- 🔄 **Hot reload** - Development mode with auto-reload

## Quick Start

### Installation

**macOS / Linux:**
```bash
curl -fsSL https://raw.githubusercontent.com/aencyorganization/adff/main/scripts/install.sh | bash
```

**Windows (PowerShell):**
```powershell
irm https://raw.githubusercontent.com/aencyorganization/adff/main/scripts/install.ps1 | iex
```

### Configuration

1. Edit `index.js` and add your bot token:
```javascript
const TOKEN = 'YOUR_BOT_TOKEN_HERE';
const PREFIX = '!';
```

2. Run your bot:
```bash
bun run index.js
```

## Creating Commands

Commands are stored in the `commands/` folder as `.js` files.

### Basic Structure

```javascript
$name[commandname]
$aliases[alias1;alias2]

Your message here!
```

### Example: Ping Command

Create `commands/ping.js`:
```javascript
$name[ping]
$aliases[p;pong]

🏓 Pong! The bot is working!
```

### Example: Embed Command

Create `commands/embed.js`:
```javascript
$name[embed]

$title[My Embed Title]
$description[This is the embed description!]
$color[#5865F2]
```

### Example: Random Text

Create `commands/random.js`:
```javascript
$name[random]

$randomText[Option 1;Option 2;Option 3]
```

## Functions Reference

### $name[name]
**Required** - Defines the command name.

```javascript
$name[ping]
```

### $aliases[alias1;alias2;...]
**Optional** - Defines command aliases.

```javascript
$aliases[p;pong;pingpong]
```

### $randomText[text1;text2;...]
Returns a random text from the arguments.

```javascript
$randomText[Heads;Tails]
$randomText[Red;Green;Blue;Yellow]
```

### $title[text]
Sets the embed title. Creates an embed automatically.

```javascript
$title[Welcome to my server!]
```

### $description[text]
Sets the embed description.

```javascript
$description[This is a detailed description of something cool!]
```

### $color[hex1;hex2;...]
Sets the embed color. If multiple colors are provided, picks one randomly.

```javascript
$color[#FF0000]
$color[#FF0000;#00FF00;#0000FF]
```

### $footer[text;iconUrl]
Sets the embed footer. Requires `$title` or `$description` to be set first.

- **Argument 1** (required): Footer text
- **Argument 2** (optional): Icon URL for the footer

```javascript
$footer[Jully Services]
$footer[Powered by ADFF;https://example.com/icon.png]
```

## Nested Functions

Functions can be nested! The inner function executes first.

```javascript
$title[$randomText[Red Title;Blue Title;Green Title]]
$color[#FF0000;#00FF00;#0000FF]
```

## Comments

Use `//` to add comments (ignored by the parser):

```javascript
// This is a comment
$name[test]
// Another comment
This is the actual message!
```

## Project Structure

```
my-bot/
├── index.js        # Main configuration file
├── vars.js         # Variables (reserved for future)
├── package.json    # Project dependencies
└── commands/       # Your commands folder
    ├── ping.js
    ├── embed.js
    └── random.js
```

## API Reference

### Programmatic Usage

```javascript
import { createADFFClient, registerFunction } from 'adff';

// Create custom function
registerFunction('myFunction', async (args, context, state) => {
  return `Hello, ${context.authorUsername}!`;
});

// Create client
const bot = createADFFClient({
  token: 'YOUR_TOKEN',
  prefix: '!',
  commandsPath: './commands/',
  debug: true
});

// Start bot
bot.start();

// Reload commands
bot.reloadCommands();

// Get loaded commands
const commands = bot.getCommands();
```

### Custom Functions

```javascript
import { registerFunction } from 'adff';

registerFunction('uppercase', async (args, context, state) => {
  return args[0]?.toUpperCase() || '';
});

// Usage in command:
// $uppercase[hello world] -> HELLO WORLD
```

## License

MIT
