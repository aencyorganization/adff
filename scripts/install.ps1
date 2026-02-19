# ============================================
# ADFF - Application Designer For Fluxer
# Installation Script for Windows (PowerShell)
# ============================================

# Colors and styling
function Write-ColorOutput {
    param([string]$Text, [string]$Color = "White")
    Write-Host $Text -ForegroundColor $Color
}

function Write-Step {
    param([string]$Message)
    Write-Host ""
    Write-Host "▸ " -ForegroundColor Cyan -NoNewline
    Write-Host $Message -ForegroundColor White
}

function Write-Success {
    param([string]$Message)
    Write-Host "  ✓ " -ForegroundColor Green -NoNewline
    Write-Host $Message
}

function Write-Error {
    param([string]$Message)
    Write-Host "  ✗ " -ForegroundColor Red -NoNewline
    Write-Host $Message
}

function Write-Warning {
    param([string]$Message)
    Write-Host "  ! " -ForegroundColor Yellow -NoNewline
    Write-Host $Message
}

function Write-Info {
    param([string]$Message)
    Write-Host "  → " -ForegroundColor Cyan -NoNewline
    Write-Host $Message
}

function Confirm {
    param([string]$Prompt, [string]$Default = "n")
    
    $choices = if ($Default -eq "y") { "[Y/n]" } else { "[y/N]" }
    $response = Read-Host "$Prompt $choices"
    
    if ([string]::IsNullOrWhiteSpace($response)) {
        return $Default -eq "y"
    }
    
    return $response -match "^[Yy]$"
}

function Show-Header {
    Clear-Host
    Write-Host ""
    Write-Host "╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
    Write-Host "║                                                           ║" -ForegroundColor Magenta
    Write-Host "║    █████╗ ███████╗ ██████╗ ██████╗ ██████╗               ║" -ForegroundColor Magenta
    Write-Host "║   ██╔══██╗██╔════╝██╔════╝██╔═══██╗██╔══██╗              ║" -ForegroundColor Magenta
    Write-Host "║   ███████║███████╗██║     ██║   ██║██║  ██║              ║" -ForegroundColor Magenta
    Write-Host "║   ██╔══██║╚════██║██║     ██║   ██║██║  ██║              ║" -ForegroundColor Magenta
    Write-Host "║   ██║  ██║███████║╚██████╗╚██████╔╝██████╔╝              ║" -ForegroundColor Magenta
    Write-Host "║   ╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═════╝ ╚═════╝               ║" -ForegroundColor Magenta
    Write-Host "║                                                           ║" -ForegroundColor Magenta
    Write-Host "║       " -ForegroundColor Magenta -NoNewline
    Write-Host "Application Designer For Fluxer" -ForegroundColor Cyan -NoNewline
    Write-Host "                ║" -ForegroundColor Magenta
    Write-Host "║                                                           ║" -ForegroundColor Magenta
    Write-Host "╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Magenta
    Write-Host ""
}

# Main installation
function Main {
    Show-Header
    
    $currentDir = Get-Location
    
    # Show installation info
    Write-Host "This script will create an ADFF bot project in:" -ForegroundColor White
    Write-Host "  $currentDir" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Files to be created:"
    Write-Host "  • " -ForegroundColor Green -NoNewline
    Write-Host "index.js      (main configuration)"
    Write-Host "  • " -ForegroundColor Green -NoNewline
    Write-Host "vars.js       (reserved for future)"
    Write-Host "  • " -ForegroundColor Green -NoNewline
    Write-Host "package.json  (project dependencies)"
    Write-Host "  • " -ForegroundColor Green -NoNewline
    Write-Host "commands/     (your commands folder)"
    Write-Host ""
    
    # Confirmation
    if (-not (Confirm "Continue with installation?" "n")) {
        Write-Host ""
        Write-Host "Installation cancelled." -ForegroundColor Yellow
        exit 0
    }
    
    # Check for Bun
    Write-Step "Checking prerequisites..."
    
    if (Get-Command bun -ErrorAction SilentlyContinue) {
        $bunVersion = bun --version
        Write-Success "Bun v$bunVersion found"
    } else {
        Write-Error "Bun is not installed!"
        Write-Host ""
        Write-Host "Please install Bun first:" -ForegroundColor Yellow
        Write-Host "  powershell -c `"irm bun.sh/install.ps1 | iex`"" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Or visit: " -ForegroundColor Yellow -NoNewline
        Write-Host "https://bun.sh" -ForegroundColor Cyan
        exit 1
    }
    
    # Create directories
    Write-Step "Creating project structure..."
    New-Item -ItemType Directory -Force -Path "commands" | Out-Null
    Write-Success "Created commands/ directory"
    
    # Create index.js
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
    
    # Create vars.js
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
$footer[Powered by ADFF]
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
    
    # Create package.json
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
    
    # Success message
    Write-Host ""
    Write-Host "╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║                    " -ForegroundColor Green -NoNewline
    Write-Host "Installation Complete!" -ForegroundColor White -NoNewline
    Write-Host "                    ║" -ForegroundColor Green
    Write-Host "╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor White
    Write-Host ""
    Write-Host "  1. Edit " -ForegroundColor Cyan -NoNewline
    Write-Host "index.js" -ForegroundColor White -NoNewline
    Write-Host " and add your bot token"
    Write-Host "  2. Create commands in the " -ForegroundColor Cyan -NoNewline
    Write-Host "commands/" -ForegroundColor White -NoNewline
    Write-Host " folder"
    Write-Host "  3. Run your bot: " -ForegroundColor Cyan -NoNewline
    Write-Host "bun run index.js" -ForegroundColor White
    Write-Host ""
    Write-Host "Documentation: " -ForegroundColor White -NoNewline
    Write-Host "https://github.com/aencyorganization/adff" -ForegroundColor Cyan
    Write-Host ""
}

# Run main
Main
