#!/bin/bash
#
# Setup Environment Configuration
# Creates a clean .env file from template
#

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

PROJECT_DIR="$HOME/3d-reconstruction"
ENV_FILE="$PROJECT_DIR/.env"
TEMPLATE_FILE="$PROJECT_DIR/.env.template"

create_clean_env() {
    log_info "Creating clean .env file..."
    
    # Use local template if available, otherwise use the one from this repo
    local template_source=""
    if [[ -f "$TEMPLATE_FILE" ]]; then
        template_source="$TEMPLATE_FILE"
    elif [[ -f "$(dirname "$0")/.env.template" ]]; then
        template_source="$(dirname "$0")/.env.template"
    else
        log_error "No .env.template found"
        return 1
    fi
    
    # Create temporary file to ensure clean creation
    local temp_file=$(mktemp)
    
    # Copy template to temporary file (no shell expansion)
    cp "$template_source" "$temp_file"
    
    # Move to final location
    mv "$temp_file" "$ENV_FILE"
    
    # Verify the file is clean (no ANSI codes)
    if grep -q $'\033\|\\033\|\\E\[\|\\x1b' "$ENV_FILE"; then
        log_error "ANSI color codes detected in .env file!"
        log_error "This indicates a problem with the template or creation process"
        return 1
    fi
    
    log_info "Clean .env file created successfully"
    log_info "Location: $ENV_FILE"
    
    # Show first few lines to verify
    echo ""
    echo "First 5 lines of .env file:"
    head -5 "$ENV_FILE"
    echo ""
    
    return 0
}

main() {
    echo "🔧 Environment Setup Script"
    echo "=========================="
    echo ""
    
    # Check if project directory exists
    if [[ ! -d "$PROJECT_DIR" ]]; then
        log_error "Project directory not found: $PROJECT_DIR"
        log_error "Run the deployment script first: ./deploy-vm.sh"
        exit 1
    fi
    
    # Backup existing .env if it exists
    if [[ -f "$ENV_FILE" ]]; then
        local backup_file="${ENV_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$ENV_FILE" "$backup_file"
        log_info "Existing .env backed up to: $backup_file"
    fi
    
    # Create clean .env file
    if create_clean_env; then
        log_info "✅ Environment configuration ready!"
        echo ""
        echo "Next steps:"
        echo "1. Edit $ENV_FILE to customize settings"
        echo "2. Activate environment: source $PROJECT_DIR/activate.sh"
        echo "3. Run reconstruction: cd $PROJECT_DIR && ./run-reconstruction.sh"
    else
        log_error "❌ Failed to create clean .env file"
        exit 1
    fi
}

# Command line interface
case "${1:-}" in
    --help|-h)
        cat << EOF
Environment Setup Script

Creates a clean .env configuration file from template.

Usage: $0 [options]

Options:
  --help, -h    Show this help message

This script:
• Creates a clean .env file from .env.template
• Ensures no ANSI color codes contaminate the file
• Backs up existing .env file if present
• Verifies the created file is properly formatted

EOF
        exit 0
        ;;
    "")
        main
        ;;
    *)
        log_error "Unknown option: $1"
        echo "Use --help for usage information"
        exit 1
        ;;
esac
