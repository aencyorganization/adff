#!/bin/bash

# ============================================
# ADFF Installation Script
# Works on macOS, Linux, and Windows (Git Bash/WSL)
# ============================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored message
print_msg() {
    echo -e "${2}${1}${NC}"
}

# Print step
print_step() {
    print_msg "\n▶ $1" "$BLUE"
}

# Print success
print_success() {
    print_msg "✓ $1" "$GREEN"
}

# Print error
print_error() {
    print_msg "✗ $1" "$RED"
}

# Print warning
print_warning() {
    print_msg "! $1" "$YELLOW"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Main installation
main() {
    print_msg "\n╔══════════════════════════════════════╗" "$BLUE"
    print_msg "║     ADFF - Fluxer Bot Framework      ║" "$BLUE"
    print_msg "║         Installation Script          ║" "$BLUE"
    print_msg "╚══════════════════════════════════════╝\n" "$BLUE"

    # Check for Bun
    print_step "Checking for Bun..."
    if command_exists bun; then
        BUN_VERSION=$(bun --version)
        print_success "Bun found (version $BUN_VERSION)"
    else
        print_error "Bun is not installed!"
        print_msg "\nPlease install Bun first:" "$YELLOW"
        print_msg "  curl -fsSL https://bun.sh/install | bash" "$YELLOW"
        print_msg "\nOr visit: https://bun.sh\n" "$YELLOW"
        exit 1
    fi

    # Create project structure
    print_step "Creating project structure..."
    
    # Create directories
    mkdir -p commands
    
    print_success "Directories created"

    # Create index.js if it doesn't exist
    print_step "Creating configuration files..."
    
    if [ ! -f "index.js" ]; then
        cat > index.js << 'INDEXEOF'
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
INDEXEOF
        print_success "Created index.js"
    else
        print_warning "index.js already exists, skipping"
    fi

    # Create vars.js if it doesn't exist
    if [ ! -f "vars.js" ]; then
        cat > vars.js << 'VARSEOF'
// ============================================
// ADFF Variables File
// ============================================
// This file is reserved for future versions
// Do not modify this file

export const vars = {
  // Reserved for future use
};
VARSEOF
        print_success "Created vars.js"
    else
        print_warning "vars.js already exists, skipping"
    fi

    # Create example commands
    print_step "Creating example commands..."
    
    if [ ! -f "commands/ping.js" ]; then
        cat > commands/ping.js << 'PINGEOF'
// Example command: ping
$name[ping]
$aliases[p;pong]

🏓 Pong! The bot is working!
PINGEOF
        print_success "Created commands/ping.js"
    else
        print_warning "commands/ping.js already exists, skipping"
    fi

    if [ ! -f "commands/embed.js" ]; then
        cat > commands/embed.js << 'EMBEDEOF'
// Example command: embed
$name[embed]
$aliases[e]

$title[Example Embed]
$description[This is an example embed created with ADFF functions!]
$color[#5865F2]
EMBEDEOF
        print_success "Created commands/embed.js"
    else
        print_warning "commands/embed.js already exists, skipping"
    fi

    if [ ! -f "commands/random.js" ]; then
        cat > commands/random.js << 'RANDOMEOF'
// Example command: random
$name[random]
$aliases[rand;roll]

$randomText[You rolled a 1!;You rolled a 2!;You rolled a 3!;You rolled a 4!;You rolled a 5!;You rolled a 6!]
RANDOMEOF
        print_success "Created commands/random.js"
    else
        print_warning "commands/random.js already exists, skipping"
    fi

    # Create package.json if it doesn't exist
    print_step "Creating package.json..."
    
    if [ ! -f "package.json" ]; then
        cat > package.json << 'PACKAGEEOF'
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
PACKAGEEOF
        print_success "Created package.json"
    else
        print_warning "package.json already exists, skipping"
    fi

    # Install dependencies
    print_step "Installing dependencies..."
    bun install
    print_success "Dependencies installed"

    # Final message
    print_msg "\n╔══════════════════════════════════════╗" "$GREEN"
    print_msg "║       Installation Complete!         ║" "$GREEN"
    print_msg "╚══════════════════════════════════════╝\n" "$GREEN"
    
    print_msg "Next steps:" "$YELLOW"
    print_msg "  1. Edit index.js and add your bot token" "$YELLOW"
    print_msg "  2. Create commands in the commands/ folder" "$YELLOW"
    print_msg "  3. Run your bot with: bun run index.js\n" "$YELLOW"
    
    print_msg "Documentation: https://github.com/aencyorganization/adff" "$BLUE"
}

# Run main
main "$@"
