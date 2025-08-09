#!/bin/bash
"""
3D Reconstruction Pipeline - Complete VM Deployment
One-command deployment from fresh Ubuntu 24.04 VM to working pipeline
"""

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step() { echo -e "${BLUE}[STEP]${NC} $1"; }
log_header() { echo -e "${BOLD}${CYAN}$1${NC}"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

print_banner() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                                                                              ║${NC}"
    echo -e "${CYAN}║                    ${BOLD}3D RECONSTRUCTION PIPELINE DEPLOYMENT${NC}${CYAN}                    ║${NC}"
    echo -e "${CYAN}║                                                                              ║${NC}"
    echo -e "${CYAN}║                   Ubuntu 24.04 + CUDA 12.6 + RTX 4090                      ║${NC}"
    echo -e "${CYAN}║                   COLMAP + gsplat + Bunny CDN                               ║${NC}"
    echo -e "${CYAN}║                                                                              ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

check_deployment_prerequisites() {
    log_step "Checking deployment prerequisites..."
    
    # Check if we're running on Ubuntu
    if ! command -v lsb_release &> /dev/null || ! lsb_release -i | grep -q "Ubuntu"; then
        log_error "This script is designed for Ubuntu systems"
        exit 1
    fi
    
    # Check Ubuntu version
    ubuntu_version=$(lsb_release -r | cut -f2)
    if [[ "$ubuntu_version" != "24.04" ]]; then
        log_warn "Script optimized for Ubuntu 24.04, detected: $ubuntu_version"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    # Check internet connectivity
    if ! ping -c 1 google.com &> /dev/null; then
        log_error "Internet connection required for deployment"
        exit 1
    fi
    
    # Check if we have sudo access
    if ! sudo -n true 2>/dev/null; then
        log_warn "This script requires sudo privileges"
        echo "You may be prompted for your password during installation"
    fi
    
    # Check available disk space
    available_gb=$(df / | awk 'NR==2 {printf "%.0f", $4/1024/1024}')
    if [[ "$available_gb" -lt 30 ]]; then
        log_error "Insufficient disk space: ${available_gb}GB available (minimum: 30GB)"
        exit 1
    fi
    
    log_info "Prerequisites check passed ✓"
}

make_scripts_executable() {
    log_step "Making scripts executable..."
    
    chmod +x "$SCRIPT_DIR"/*.sh
    chmod +x "$SCRIPT_DIR/scripts"/*.py
    
    log_info "Scripts made executable"
}

run_system_setup() {
    log_header "Phase 1: System Setup (CUDA, Dependencies)"
    
    if [[ ! -f "$SCRIPT_DIR/setup-system.sh" ]]; then
        log_error "setup-system.sh not found"
        exit 1
    fi
    
    cd "$SCRIPT_DIR"
    ./setup-system.sh
    
    log_info "System setup completed ✓"
}

run_dependency_build() {
    log_header "Phase 2: Building Dependencies (COLMAP, Python)"
    
    if [[ ! -f "$SCRIPT_DIR/build-deps.sh" ]]; then
        log_error "build-deps.sh not found"
        exit 1
    fi
    
    # Source environment to ensure CUDA is available
    if [[ -f "$HOME/.bashrc" ]]; then
        source "$HOME/.bashrc"
    fi
    
    cd "$SCRIPT_DIR"
    ./build-deps.sh
    
    log_info "Dependency build completed ✓"
}

run_environment_setup() {
    log_header "Phase 3: Environment Configuration"
    
    if [[ ! -f "$SCRIPT_DIR/setup-env.sh" ]]; then
        log_error "setup-env.sh not found"
        exit 1
    fi
    
    cd "$SCRIPT_DIR"
    ./setup-env.sh
    
    log_info "Environment setup completed ✓"
}

verify_installation() {
    log_header "Phase 4: Installation Verification"
    
    # Check if the project directory exists
    if [[ ! -d "$HOME/3d-reconstruction" ]]; then
        log_error "Project directory not created"
        return 1
    fi
    
    # Check if activation script exists
    if [[ ! -f "$HOME/3d-reconstruction/activate.sh" ]]; then
        log_error "Activation script not found"
        return 1
    fi
    
    # Try to activate environment and test
    log_step "Testing environment activation..."
    source "$HOME/3d-reconstruction/activate.sh"
    
    # Test Python imports
    log_step "Testing Python packages..."
    if python3 -c "import torch; print(f'PyTorch: {torch.__version__}')" 2>/dev/null; then
        log_info "PyTorch: ✓"
    else
        log_error "PyTorch import failed"
        return 1
    fi
    
    if python3 -c "import gsplat; print('gsplat: OK')" 2>/dev/null; then
        log_info "gsplat: ✓"
    else
        log_error "gsplat import failed"
        return 1
    fi
    
    # Test CUDA availability
    if python3 -c "import torch; assert torch.cuda.is_available(); print('CUDA: Available')" 2>/dev/null; then
        log_info "CUDA: ✓ Available"
    else
        log_warn "CUDA: Not available (reconstruction will be slower)"
    fi
    
    # Test COLMAP
    if command -v colmap &> /dev/null; then
        log_info "COLMAP: ✓ $(colmap --version 2>&1 | head -1)"
    else
        log_error "COLMAP not found in PATH"
        return 1
    fi
    
    log_info "Installation verification passed ✓"
    return 0
}

copy_pipeline_scripts() {
    log_step "Copying pipeline scripts to project directory..."
    
    local project_dir="$HOME/3d-reconstruction"
    
    # Copy main pipeline script
    if [[ -f "$SCRIPT_DIR/run-reconstruction.sh" ]]; then
        cp "$SCRIPT_DIR/run-reconstruction.sh" "$project_dir/"
        chmod +x "$project_dir/run-reconstruction.sh"
    fi
    
    # Copy Python scripts
    if [[ -d "$SCRIPT_DIR/scripts" ]]; then
        cp -r "$SCRIPT_DIR/scripts" "$project_dir/"
        chmod +x "$project_dir/scripts"/*.py
    fi
    
    log_info "Pipeline scripts copied to $project_dir"
}

configure_bunny_cdn() {
    echo ""
    log_step "Optional: Bunny CDN Configuration"
    echo ""
    echo -e "${YELLOW}Bunny CDN provides cloud storage for your images and results.${NC}"
    echo -e "${YELLOW}You can skip this and use local images instead.${NC}"
    echo ""
    
    read -p "Do you want to configure Bunny CDN now? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        echo -e "${CYAN}Bunny CDN Configuration${NC}"
        echo ""
        
        # Ask for API key only
        echo -n "Enter your Bunny CDN API key: "
        read -s bunny_api_key
        echo
        
        if [[ -z "$bunny_api_key" ]]; then
            log_warn "No API key provided, skipping CDN configuration"
            return 0
        fi
        
        # Update .env file
        local env_file="$HOME/3d-reconstruction/.env"
        
        if [[ -f "$env_file" ]]; then
            # Update existing API key line or add it
            if grep -q "^BUNNY_API_KEY=" "$env_file"; then
                sed -i "s/^BUNNY_API_KEY=.*/BUNNY_API_KEY=$bunny_api_key/" "$env_file"
            else
                echo "BUNNY_API_KEY=$bunny_api_key" >> "$env_file"
            fi
            
            log_info "Bunny CDN API key configured ✓"
            echo ""
            echo -e "${GREEN}CDN is now ready to use!${NC}"
            echo "The pipeline will automatically download/upload images when you run reconstructions."
        else
            log_error "Environment file not found: $env_file"
        fi
    else
        log_info "Skipping Bunny CDN configuration"
        echo "You can configure it later by editing: ~/3d-reconstruction/.env"
    fi
    
    echo ""
}

display_completion_summary() {
    echo ""
    log_header "🎉 DEPLOYMENT COMPLETED SUCCESSFULLY!"
    echo ""
    
    echo -e "${YELLOW}Installation Summary:${NC}"
    echo "  📁 Project Directory: ~/3d-reconstruction"
    echo "  🔧 CUDA Version: $(nvcc --version 2>/dev/null | grep "release" | grep -o "V[0-9.]*" | sed 's/V//' || echo 'Not available')"
    echo "  🐍 Python: $(python3 --version | grep -o "[0-9.]*")"
    echo "  🎯 PyTorch: $(python3 -c 'import torch; print(torch.__version__)' 2>/dev/null || echo 'Not available')"
    echo "  📷 COLMAP: $(colmap --version 2>&1 | head -1 || echo 'Not available')"
    echo "  🎮 GPU: $(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -1 || echo 'Not detected')"
    
    echo ""
    echo -e "${YELLOW}Quick Start:${NC}"
    echo "  1. Activate environment:"
    echo "     ${CYAN}source ~/3d-reconstruction/activate.sh${NC}"
    echo ""
    echo "  2. Place test images (if not using CDN):"
    echo "     ${CYAN}cp /path/to/images/* ~/3d-reconstruction/data/images/${NC}"
    echo ""
    echo "  3. Run reconstruction:"
    echo "     ${CYAN}cd ~/3d-reconstruction && ./run-reconstruction.sh${NC}"
    echo ""
    
    echo -e "${YELLOW}Helper Scripts:${NC}"
    echo "  📊 Check system status: ${CYAN}~/3d-reconstruction/check-status.sh${NC}"
    echo "  📖 Quick start guide: ${CYAN}~/3d-reconstruction/quick-start.sh${NC}"
    echo ""
    
    echo -e "${YELLOW}Documentation:${NC}"
    echo "  • Environment variables: ~/3d-reconstruction/.env"
    echo "  • Configuration template: ~/3d-reconstruction/.env.template"
    echo "  • Results will be saved to: ~/3d-reconstruction/output/results/"
    
    if command -v nvidia-smi &> /dev/null; then
        local gpu_mem=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits 2>/dev/null | head -1)
        if [[ -n "$gpu_mem" ]]; then
            echo ""
            echo -e "${GREEN}🚀 System ready for 3D reconstruction with ${gpu_mem}MB GPU memory!${NC}"
        fi
    fi
    
    echo ""
}

handle_error() {
    local exit_code=$?
    local line_number=$1
    
    echo ""
    log_error "Deployment failed at line $line_number (exit code: $exit_code)"
    echo ""
    echo -e "${YELLOW}Troubleshooting:${NC}"
    echo "  • Check system requirements (Ubuntu 24.04, 30GB+ disk space)"
    echo "  • Ensure internet connection is stable"
    echo "  • Verify sudo privileges are available"
    echo "  • Check the error messages above for specific issues"
    echo ""
    echo -e "${YELLOW}Manual deployment:${NC}"
    echo "  1. ${CYAN}./setup-system.sh${NC}     # Install system dependencies"
    echo "  2. ${CYAN}source ~/.bashrc${NC}      # Reload environment"
    echo "  3. ${CYAN}./build-deps.sh${NC}       # Build COLMAP and Python packages"
    echo "  4. ${CYAN}./setup-env.sh${NC}        # Configure environment"
    echo ""
    
    exit $exit_code
}

main() {
    local start_time=$(date +%s)
    
    print_banner
    
    log_info "Starting 3D reconstruction pipeline deployment..."
    log_info "This process may take 30-60 minutes depending on your system"
    
    # Set up error handling
    trap 'handle_error $LINENO' ERR
    
    # Run deployment phases
    check_deployment_prerequisites
    make_scripts_executable
    run_system_setup
    
    # Note about potential reboot requirement
    if [[ -f "/var/run/reboot-required" ]]; then
        echo ""
        log_warn "System reboot may be required after CUDA/driver installation"
        read -p "Continue without reboot? (drivers may not work until reboot) [y/N]: " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Please reboot and re-run this script"
            exit 0
        fi
    fi
    
    run_dependency_build
    run_environment_setup
    copy_pipeline_scripts
    
    if verify_installation; then
        # Configure Bunny CDN after successful installation
        configure_bunny_cdn
        
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        local minutes=$((duration / 60))
        
        display_completion_summary
        echo -e "${CYAN}Total deployment time: ${minutes} minutes${NC}"
        
        return 0
    else
        log_error "Installation verification failed"
        return 1
    fi
}

# Command line interface
case "${1:-}" in
    --help|-h)
        cat << EOF
3D Reconstruction Pipeline - Complete VM Deployment

This script performs a complete deployment of the 3D reconstruction pipeline
on a fresh Ubuntu 24.04 VM, including:

• CUDA 12.6 installation and GPU driver setup
• COLMAP compilation with CUDA support  
• Python environment with PyTorch and gsplat
• Bunny CDN integration for cloud storage
• Complete project structure and configuration

Usage: $0 [options]

Options:
  --help, -h        Show this help message
  --verify-only     Only run verification tests
  --status          Show system status

Requirements:
• Ubuntu 24.04 LTS
• 30+ GB available disk space
• 8+ GB RAM (16+ GB recommended)
• Internet connection
• Sudo privileges
• NVIDIA GPU (optional but recommended)

The deployment process takes approximately 30-60 minutes.

EOF
        exit 0
        ;;
    --verify-only)
        if verify_installation; then
            echo "✅ Verification passed"
            exit 0
        else
            echo "❌ Verification failed"
            exit 1
        fi
        ;;
    --status)
        if [[ -f "$HOME/3d-reconstruction/check-status.sh" ]]; then
            source "$HOME/3d-reconstruction/check-status.sh"
        else
            echo "Status script not found - run deployment first"
            exit 1
        fi
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
