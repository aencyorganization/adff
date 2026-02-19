# ============================================
# ADFF Installation Script for Windows
# PowerShell Version
# ============================================

# Colors
function Write-ColorOutput($ForegroundColor) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    if ($args) {
        Write-Output $args
    }
    $host.UI.RawUI.ForegroundColor = $fc
}

function Write-Step($message) {
    Write-ColorOutput Cyan "`n▶ $message"
}

function Write-Success($message) {
    Write-ColorOutput Green "✓ $message"
}

function Write-Error($message) {
    Write-ColorOutput Red "✗ $message"
}

function Write-Warning($message) {
    Write-ColorOutput Yellow "! $message"
}

# Main installation
function Main {
    Write-ColorOutput Blue "`n╔══════════════════════════════════════╗"
    Write-ColorOutput Blue "║     ADFF - Fluxer Bot Framework      ║"
    Write-ColorOutput Blue "║         Installation Script          ║"
    Write-ColorOutput Blue "╚══════════════════════════════════════╝`n"

    # Check for Bun
    Write-Step "Checking for Bun..."
    if (Get-Command bun -ErrorAction SilentlyContinue) {
        $bunVersion = bun --version
        Write-Success "Bun found (version $bunVersion)"
    } else {
        Write-Error "Bun is not installed!"
        Write-ColorOutput Yellow "`nPlease install Bun first:"
        Write-ColorOutput Yellow "  powershell -c `"irm bun.sh/install.ps1 | iex`""
        Write-ColorOutput Yellow "`nOr visit: https://bun.sh`n"
        exit 1
    }

    # Create project structure
    Write-Step "Creating project structure..."
    
    # Create directories
    New-Item -ItemType Directory -Force -Path "commands" | Out-Null
    
    Write-Success "Directories created"

    # Create index.js if it doesn't exist
    Write-Step "Creating configuration files..."
    
    if (-not (Test-Path "index.js")) {
        $indexContent = @'
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
'@
        Set-Content -Path "index.js" -Value $indexContent -NoNewline
        Write-Success "Created index.js"
    } else {
        Write-Warning "index.js already exists, skipping"
    }

    # Create vars.js if it doesn't exist
    if (-not (Test-Path "vars.js")) {
        $varsContent = @'
// ============================================
// ADFF Variables File
// ============================================
// This file is reserved for future versions
// Do not modify this file

export const vars = {
  // Reserved for future use
};
'@
        Set-Content -Path "vars.js" -Value $varsContent -NoNewline
        Write-Success "Created vars.js"
    } else {
        Write-Warning "vars.js already exists, skipping"
    }

    # Create example commands
    Write-Step "Creating example commands..."
    
    if (-not (Test-Path "commands/ping.js")) {
        $pingContent = @'
// Example command: ping
$name[ping]
$aliases[p;pong]

🏓 Pong! The bot is working!
'@
        Set-Content -Path "commands/ping.js" -Value $pingContent -NoNewline
        Write-Success "Created commands/ping.js"
    } else {
        Write-Warning "commands/ping.js already exists, skipping"
    }

    if (-not (Test-Path "commands/embed.js")) {
        $embedContent = @'
// Example command: embed
$name[embed]
$aliases[e]

$title[Example Embed]
$description[This is an example embed created with ADFF functions!]
$color[#5865F2]
'@
        Set-Content -Path "commands/embed.js" -Value $embedContent -NoNewline
        Write-Success "Created commands/embed.js"
    } else {
        Write-Warning "commands/embed.js already exists, skipping"
    }

    if (-not (Test-Path "commands/random.js")) {
        $randomContent = @'
// Example command: random
$name[random]
$aliases[rand;roll]

$randomText[You rolled a 1!;You rolled a 2!;You rolled a 3!;You rolled a 4!;You rolled a 5!;You rolled a 6!]
'@
        Set-Content -Path "commands/random.js" -Value $randomContent -NoNewline
        Write-Success "Created commands/random.js"
    } else {
        Write-Warning "commands/random.js already exists, skipping"
    }

    # Create package.json if it doesn't exist
    Write-Step "Creating package.json..."
    
    if (-not (Test-Path "package.json")) {
        $packageContent = @'
{
  "name": "my-adff-bot",
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "start": "bun run index.js",
    "dev": "bun run --watch index.js"
  },
  "dependencies": {
    "adff": "latest"
  }
}
'@
        Set-Content -Path "package.json" -Value $packageContent -NoNewline
        Write-Success "Created package.json"
    } else {
        Write-Warning "package.json already exists, skipping"
    }

    # Install dependencies
    Write-Step "Installing dependencies..."
    bun install
    Write-Success "Dependencies installed"

    # Final message
    Write-ColorOutput Green "`n╔══════════════════════════════════════╗"
    Write-ColorOutput Green "║       Installation Complete!         ║"
    Write-ColorOutput Green "╚══════════════════════════════════════╝`n"
    
    Write-ColorOutput Yellow "Next steps:"
    Write-ColorOutput Yellow "  1. Edit index.js and add your bot token"
    Write-ColorOutput Yellow "  2. Create commands in the commands/ folder"
    Write-ColorOutput Yellow "  3. Run your bot with: bun run index.js`n"
    
    Write-ColorOutput Cyan "Documentation: https://github.com/aencyorganization/adff"
}

# Run main
Main
