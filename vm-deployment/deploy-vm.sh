#!/bin/bash
"""
3D Reconstruction Pipeline - VM-Compatible Deployment
Uses existing CUDA installation, no driver conflicts
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
    echo -e "${CYAN}║                    ${BOLD}3D RECONSTRUCTION PIPELINE (VM)${NC}${CYAN}                       ║${NC}"
    echo -e "${CYAN}║                                                                              ║${NC}"
    echo -e "${CYAN}║                   Uses Existing CUDA + No Driver Conflicts                  ║${NC}"
    echo -e "${CYAN}║                   COLMAP + gsplat + Auto-Detection                          ║${NC}"
    echo -e "${CYAN}║                                                                              ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

check_vm_prerequisites() {
    log_step "Checking VM prerequisites..."
    
    # Check if we're running on Ubuntu
    if ! command -v lsb_release &> /dev/null || ! lsb_release -i | grep -q "Ubuntu"; then
        log_error "This script is designed for Ubuntu systems"
        exit 1
    fi
    
    # Check Ubuntu version
    ubuntu_version=$(lsb_release -r | cut -f2)
    log_info "Ubuntu version: $ubuntu_version"
    
    # Check for existing NVIDIA drivers
    if ! command -v nvidia-smi &> /dev/null; then
        log_error "nvidia-smi not found - NVIDIA drivers not installed on VM"
        log_error "Please ensure your VM has NVIDIA drivers pre-installed"
        exit 1
    fi
    
    # Check for existing CUDA
    cuda_found=false
    if command -v nvcc &> /dev/null; then
        cuda_version=$(nvcc --version | grep "release" | grep -o "V[0-9]\+\.[0-9]\+" | sed 's/V//')
        log_info "CUDA toolkit found: $cuda_version"
        cuda_found=true
    else
        # Try to find CUDA in common locations
        for cuda_dir in /usr/local/cuda* /opt/cuda* /usr/cuda*; do
            if [[ -d "$cuda_dir" && -f "$cuda_dir/bin/nvcc" ]]; then
                cuda_version=$($cuda_dir/bin/nvcc --version | grep "release" | grep -o "V[0-9]\+\.[0-9]\+" | sed 's/V//')
                log_info "CUDA toolkit found: $cuda_version at $cuda_dir"
                cuda_found=true
                break
            fi
        done
    fi
    
    if [[ "$cuda_found" == "false" ]]; then
        log_error "CUDA toolkit not found on VM"
        log_error "Please ensure your VM has CUDA pre-installed"
        exit 1
    fi
    
    # Check GPU
    gpu_info=$(nvidia-smi --query-gpu=name,memory.total --format=csv,noheader,nounits 2>/dev/null | head -1)
    log_info "GPU detected: $gpu_info"
    
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
    if [[ "$available_gb" -lt 20 ]]; then
        log_error "Insufficient disk space: ${available_gb}GB available (minimum: 20GB)"
        exit 1
    fi
    
    log_info "VM prerequisites check passed ✓"
}

make_scripts_executable() {
    log_step "Making scripts executable..."
    
    chmod +x "$SCRIPT_DIR"/*.sh
    if [[ -d "$SCRIPT_DIR/scripts" ]]; then
        chmod +x "$SCRIPT_DIR/scripts"/*.py
    fi
    
    log_info "Scripts made executable"
}

run_vm_system_setup() {
    log_header "Phase 1: VM System Setup (Using Existing CUDA)"
    
    if [[ ! -f "$SCRIPT_DIR/setup-system-vm.sh" ]]; then
        log_error "setup-system-vm.sh not found"
        exit 1
    fi
    
    cd "$SCRIPT_DIR"
    ./setup-system-vm.sh
    
    log_info "VM system setup completed ✓"
}

run_vm_dependency_build() {
    log_header "Phase 2: Building Dependencies (Auto-Detecting CUDA)"
    
    if [[ ! -f "$SCRIPT_DIR/build-deps-vm.sh" ]]; then
        log_error "build-deps-vm.sh not found"
        exit 1
    fi
    
    # Source environment to ensure CUDA is available
    if [[ -f "$HOME/.bashrc" ]]; then
        source "$HOME/.bashrc"
    fi
    
    cd "$SCRIPT_DIR"
    ./build-deps-vm.sh
    
    log_info "VM dependency build completed ✓"
}

run_environment_setup() {
    log_header "Phase 3: Environment Configuration"
    
    if [[ -f "$SCRIPT_DIR/setup-env.sh" ]]; then
        cd "$SCRIPT_DIR"
        ./setup-env.sh
    else
        log_warn "setup-env.sh not found, creating basic environment"
        create_basic_environment
    fi
    
    log_info "Environment setup completed ✓"
}

create_basic_environment() {
    log_step "Creating basic environment configuration..."
    
    local project_dir="$HOME/3d-reconstruction"
    
    # Create .env file
    cat > "$project_dir/.env" << 'EOF'
# 3D Reconstruction Pipeline Configuration (VM Compatible)

# Bunny CDN Configuration (optional)
BUNNY_API_KEY=
BUNNY_STORAGE_ZONE=
BUNNY_HOSTNAME=

# Processing Settings
MAX_IMAGE_SIZE=2048
COLMAP_QUALITY=high
GAUSSIAN_ITERATIONS=30000

# Output Settings
OUTPUT_FORMAT=ply
ENABLE_WEB_VIEWER=true

# Performance Settings (will be auto-detected)
USE_GPU=auto
CUDA_MEMORY_FRACTION=0.8
EOF
    
    # Create .env.template
    cp "$project_dir/.env" "$project_dir/.env.template"
    
    log_info "Basic environment configuration created"
}

verify_vm_installation() {
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
        log_warn "CUDA: Not available in PyTorch (may be CPU-only)"
    fi
    
    # Test COLMAP
    if command -v colmap &> /dev/null; then
        log_info "COLMAP: ✓ $(colmap --version 2>&1 | head -1)"
    else
        log_error "COLMAP not found in PATH"
        return 1
    fi
    
    log_info "VM installation verification passed ✓"
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

create_vm_status_script() {
    log_step "Creating VM status check script..."
    
    cat > ~/3d-reconstruction/check-vm-status.sh << 'EOF'
#!/bin/bash
# VM Status Check for 3D Reconstruction Pipeline

echo "=== VM 3D Reconstruction Pipeline Status ==="
echo ""

# System Info
echo "System Information:"
echo "  OS: $(lsb_release -d | cut -f2)"
echo "  Kernel: $(uname -r)"
echo "  Uptime: $(uptime -p)"
echo ""

# GPU Info
echo "GPU Information:"
if command -v nvidia-smi &> /dev/null; then
    echo "  Driver: $(nvidia-smi --query-gpu=driver_version --format=csv,noheader | head -1)"
    echo "  GPU: $(nvidia-smi --query-gpu=name --format=csv,noheader | head -1)"
    echo "  Memory: $(nvidia-smi --query-gpu=memory.total --format=csv,noheader | head -1)"
    echo "  Temperature: $(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader | head -1)°C"
else
    echo "  NVIDIA drivers not found"
fi
echo ""

# CUDA Info
echo "CUDA Information:"
if command -v nvcc &> /dev/null; then
    echo "  Version: $(nvcc --version | grep "release" | grep -o "V[0-9.]*")"
    echo "  Path: $(which nvcc | sed 's|/bin/nvcc||')"
else
    echo "  CUDA toolkit not found in PATH"
fi
echo ""

# Python Environment
echo "Python Environment:"
if [[ -f ~/3d-reconstruction/activate.sh ]]; then
    source ~/3d-reconstruction/activate.sh > /dev/null 2>&1
    echo "  Python: $(python --version 2>&1)"
    echo "  PyTorch: $(python -c 'import torch; print(torch.__version__)' 2>/dev/null || echo 'Not available')"
    echo "  CUDA in PyTorch: $(python -c 'import torch; print("Yes" if torch.cuda.is_available() else "No")' 2>/dev/null)"
    echo "  gsplat: $(python -c 'import gsplat; print("Available")' 2>/dev/null || echo 'Not available')"
else
    echo "  Environment not set up"
fi
echo ""

# COLMAP
echo "COLMAP:"
if command -v colmap &> /dev/null; then
    echo "  Version: $(colmap --version 2>&1 | head -1)"
    echo "  CUDA: $(colmap --help 2>&1 | grep -q "CUDA enabled" && echo "Enabled" || echo "Disabled")"
else
    echo "  Not installed"
fi
echo ""

# Disk Space
echo "Disk Space:"
echo "  Available: $(df -h / | awk 'NR==2 {print $4}')"
echo "  Used: $(df -h / | awk 'NR==2 {print $3}')"
echo ""

# Project Status
echo "Project Status:"
if [[ -d ~/3d-reconstruction ]]; then
    echo "  Project directory: ✓ Exists"
    echo "  Data directory: $(ls ~/3d-reconstruction/data/images/ 2>/dev/null | wc -l) images"
    echo "  Results: $(ls ~/3d-reconstruction/output/results/ 2>/dev/null | wc -l) reconstructions"
else
    echo "  Project directory: ✗ Not found"
fi
EOF

    chmod +x ~/3d-reconstruction/check-vm-status.sh
    log_info "VM status script created: ~/3d-reconstruction/check-vm-status.sh"
}

display_vm_completion_summary() {
    echo ""
    log_header "🎉 VM DEPLOYMENT COMPLETED SUCCESSFULLY!"
    echo ""
    
    # Get actual system info
    local cuda_version=$(nvcc --version 2>/dev/null | grep "release" | grep -o "V[0-9.]*" | sed 's/V//' || echo 'Not available')
    local gpu_name=$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -1 || echo 'Not detected')
    local gpu_mem=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits 2>/dev/null | head -1 || echo 'Unknown')
    
    echo -e "${YELLOW}VM Configuration Summary:${NC}"
    echo "  📁 Project Directory: ~/3d-reconstruction"
    echo "  🔧 CUDA Version: $cuda_version (existing installation)"
    echo "  🐍 Python: $(python3 --version | grep -o "[0-9.]*")"
    echo "  🎯 PyTorch: $(python3 -c 'import torch; print(torch.__version__)' 2>/dev/null || echo 'Not available')"
    echo "  📷 COLMAP: $(colmap --version 2>&1 | head -1 || echo 'Not available')"
    echo "  🎮 GPU: $gpu_name (${gpu_mem}MB)"
    
    echo ""
    echo -e "${YELLOW}Quick Start:${NC}"
    echo "  1. Activate environment:"
    echo "     ${CYAN}source ~/3d-reconstruction/activate.sh${NC}"
    echo ""
    echo "  2. Check system status:"
    echo "     ${CYAN}~/3d-reconstruction/check-vm-status.sh${NC}"
    echo ""
    echo "  3. Place test images:"
    echo "     ${CYAN}cp /path/to/images/* ~/3d-reconstruction/data/images/${NC}"
    echo ""
    echo "  4. Run reconstruction:"
    echo "     ${CYAN}cd ~/3d-reconstruction && ./run-reconstruction.sh${NC}"
    echo ""
    
    echo -e "${YELLOW}VM-Specific Features:${NC}"
    echo "  ✅ Uses existing CUDA installation"
    echo "  ✅ No driver conflicts"
    echo "  ✅ Auto-detects GPU capabilities"
    echo "  ✅ Compatible PyTorch installation"
    echo "  ✅ Optimized for VM environments"
    
    echo ""
    echo -e "${GREEN}🚀 VM is ready for 3D reconstruction with ${gpu_mem}MB GPU memory!${NC}"
    echo ""
}

handle_error() {
    local exit_code=$?
    local line_number=$1
    
    echo ""
    log_error "VM deployment failed at line $line_number (exit code: $exit_code)"
    echo ""
    echo -e "${YELLOW}VM-Specific Troubleshooting:${NC}"
    echo "  • Ensure VM has NVIDIA drivers pre-installed"
    echo "  • Verify CUDA toolkit is available on VM"
    echo "  • Check VM has sufficient resources (8GB+ RAM, 20GB+ disk)"
    echo "  • Ensure internet connection is stable"
    echo ""
    echo -e "${YELLOW}Manual VM deployment:${NC}"
    echo "  1. ${CYAN}./setup-system-vm.sh${NC}     # Use existing CUDA"
    echo "  2. ${CYAN}source ~/.bashrc${NC}         # Reload environment"
    echo "  3. ${CYAN}./build-deps-vm.sh${NC}       # Build with auto-detection"
    echo ""
    
    exit $exit_code
}

main() {
    local start_time=$(date +%s)
    
    print_banner
    
    log_info "Starting VM-compatible 3D reconstruction pipeline deployment..."
    log_info "This process will use your VM's existing CUDA installation"
    
    # Set up error handling
    trap 'handle_error $LINENO' ERR
    
    # Run deployment phases
    check_vm_prerequisites
    make_scripts_executable
    run_vm_system_setup
    run_vm_dependency_build
    run_environment_setup
    copy_pipeline_scripts
    create_vm_status_script
    
    if verify_vm_installation; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        local minutes=$((duration / 60))
        
        display_vm_completion_summary
        echo -e "${CYAN}Total VM deployment time: ${minutes} minutes${NC}"
        
        return 0
    else
        log_error "VM installation verification failed"
        return 1
    fi
}

# Command line interface
case "${1:-}" in
    --help|-h)
        cat << EOF
3D Reconstruction Pipeline - VM-Compatible Deployment

This script performs a complete deployment of the 3D reconstruction pipeline
on a VM with existing CUDA installation, including:

• Uses existing CUDA installation (no driver conflicts)
• Auto-detects CUDA version and GPU capabilities
• Installs compatible PyTorch version
• COLMAP compilation with detected CUDA support  
• Python environment with gsplat
• Complete project structure and configuration

Usage: $0 [options]

Options:
  --help, -h        Show this help message
  --verify-only     Only run verification tests
  --status          Show VM system status

Requirements:
• Ubuntu (any recent version)
• Pre-installed NVIDIA drivers
• Pre-installed CUDA toolkit
• 20+ GB available disk space
• 8+ GB RAM (16+ GB recommended)
• Internet connection
• Sudo privileges

The VM deployment process takes approximately 20-40 minutes.

EOF
        exit 0
        ;;
    --verify-only)
        if verify_vm_installation; then
            echo "✅ VM verification passed"
            exit 0
        else
            echo "❌ VM verification failed"
            exit 1
        fi
        ;;
    --status)
        if [[ -f "$HOME/3d-reconstruction/check-vm-status.sh" ]]; then
            source "$HOME/3d-reconstruction/check-vm-status.sh"
        else
            echo "VM status script not found - run deployment first"
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
