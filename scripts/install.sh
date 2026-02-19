#!/bin/bash

# ============================================
# ADFF - Application Designer For Fluxer
# Installation Script
# Works on macOS, Linux, and Windows (Git Bash/WSL)
# ============================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Get current directory
CURRENT_DIR=$(pwd)

# Print functions
print_header() {
    echo -e "${BOLD}${MAGENTA}ADFF - Application Designer For Fluxer${NC}"
    echo ""
}

print_step() {
    echo -e "\n${BLUE}▸${NC} ${BOLD}$1${NC}"
}

print_success() {
    echo -e "${GREEN}  ✓${NC} $1"
}

print_error() {
    echo -e "${RED}  ✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}  !${NC} $1"
}

print_info() {
    echo -e "${CYAN}  →${NC} $1"
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

confirm() {
    local prompt="$1"
    local default="${2:-n}"
    
    if [[ "$default" == "y" ]]; then
        prompt="$prompt [Y/n]: "
    else
        prompt="$prompt [y/N]: "
    fi
    
    echo -ne "${YELLOW}$prompt${NC}"
    read -r response
    
    response=${response:-$default}
    [[ "$response" =~ ^[Yy]$ ]]
}

# Main installation
main() {
    print_header
    
    # Show installation info
    echo -e "${BOLD}This script will create an ADFF bot project in:${NC}"
    echo -e "${CYAN}  $CURRENT_DIR${NC}"
    echo ""
    echo -e "Files to be created:"
    echo -e "  ${GREEN}•${NC} index.js      ${GRAY}(main configuration)${NC}"
    echo -e "  ${GREEN}•${NC} vars.js       ${GRAY}(reserved for future)${NC}"
    echo -e "  ${GREEN}•${NC} package.json  ${GRAY}(project dependencies)${NC}"
    echo -e "  ${GREEN}•${NC} commands/     ${GRAY}(your commands folder)${NC}"
    echo ""
    
    # Confirmation
    if ! confirm "Continue with installation?" "n"; then
        echo -e "\n${YELLOW}Installation cancelled.${NC}"
        exit 0
    fi
    
    # Check for Bun
    print_step "Checking prerequisites..."
    
    if command_exists bun; then
        BUN_VERSION=$(bun --version)
        print_success "Bun v${BUN_VERSION} found"
    else
        print_error "Bun is not installed!"
        echo ""
        echo -e "Please install Bun first:"
        echo -e "  ${CYAN}curl -fsSL https://bun.sh/install | bash${NC}"
        echo ""
        echo -e "Or visit: ${CYAN}https://bun.sh${NC}"
        exit 1
    fi
    
    # Create directories
    print_step "Creating project structure..."
    mkdir -p commands
    print_success "Created commands/ directory"
    
    # Create index.js
    print_step "Creating configuration files..."
    
    if [ ! -f "index.js" ]; then
        cat > index.js << 'EOF'
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
EOF
        print_success "Created index.js"
    else
        print_warning "index.js already exists, skipping"
    fi
    
    # Create vars.js
    if [ ! -f "vars.js" ]; then
        cat > vars.js << 'EOF'
// ============================================
// ADFF Variables File
// ============================================
// This file is reserved for future versions
// Do not modify this file

export const vars = {
  // Reserved for future use
};
EOF
        print_success "Created vars.js"
    else
        print_warning "vars.js already exists, skipping"
    fi
    
    # Create example commands
    print_step "Creating example commands..."
    
    if [ ! -f "commands/ping.js" ]; then
        cat > commands/ping.js << 'EOF'
// Example command: ping
$name[ping]
$aliases[p;pong]

🏓 Pong! The bot is working!
EOF
        print_success "Created commands/ping.js"
    else
        print_warning "commands/ping.js already exists, skipping"
    fi
    
    if [ ! -f "commands/embed.js" ]; then
        cat > commands/embed.js << 'EOF'
// Example command: embed
$name[embed]
$aliases[e]

$title[Example Embed]
$description[This is an example embed created with ADFF functions!]
$color[#5865F2]
$footer[Powered by ADFF]
EOF
        print_success "Created commands/embed.js"
    else
        print_warning "commands/embed.js already exists, skipping"
    fi
    
    if [ ! -f "commands/random.js" ]; then
        cat > commands/random.js << 'EOF'
// Example command: random
$name[random]
$aliases[rand;roll]

$randomText[You rolled a 1!;You rolled a 2!;You rolled a 3!;You rolled a 4!;You rolled a 5!;You rolled a 6!]
EOF
        print_success "Created commands/random.js"
    else
        print_warning "commands/random.js already exists, skipping"
    fi
    
    # Create package.json
    print_step "Creating package.json..."
    
    if [ ! -f "package.json" ]; then
        cat > package.json << 'EOF'
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
EOF
        print_success "Created package.json"
    else
        print_warning "package.json already exists, skipping"
    fi
    
    # Install dependencies
    print_step "Installing dependencies..."
    bun install
    print_success "Dependencies installed"
    
    # Success message
    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║${NC                    ${BOLD}Installation Complete!${NC}                    ${GREEN}║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BOLD}Next steps:${NC}"
    echo ""
    echo -e "  ${CYAN}1.${NC} Edit ${BOLD}index.js${NC} and add your bot token"
    echo -e "  ${CYAN}2.${NC} Create commands in the ${BOLD}commands/${NC} folder"
    echo -e "  ${CYAN}3.${NC} Run your bot: ${BOLD}bun run index.js${NC}"
    echo ""
    echo -e "${BOLD}Documentation:${NC} ${CYAN}https://github.com/aencyorganization/adff${NC}"
    echo ""
}

# Run main
main "$@"
