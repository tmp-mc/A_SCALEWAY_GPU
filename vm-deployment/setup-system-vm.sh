#!/bin/bash
"""
VM-Compatible System Setup Script for 3D Reconstruction Pipeline
Uses existing CUDA installation and installs only system dependencies
"""

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step() { echo -e "${BLUE}[STEP]${NC} $1"; }

print_banner() {
    echo -e "${BLUE}================================================${NC}"
    echo -e "${BLUE}  3D Reconstruction Pipeline - VM Setup        ${NC}"
    echo -e "${BLUE}  Using Existing CUDA Installation             ${NC}"
    echo -e "${BLUE}================================================${NC}"
}

check_ubuntu_version() {
    log_step "Checking Ubuntu version..."
    
    if ! lsb_release -r | grep -q "24.04"; then
        log_warn "This script is optimized for Ubuntu 24.04 LTS"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    else
        log_info "Ubuntu 24.04 LTS detected ✓"
    fi
}

check_system_requirements() {
    log_step "Checking system requirements..."
    
    # Check RAM
    ram_gb=$(free -g | awk 'NR==2{printf "%.0f", $2}')
    if (( ram_gb < 8 )); then
        log_error "Insufficient RAM: ${ram_gb}GB (minimum 8GB required)"
        exit 1
    fi
    log_info "RAM: ${ram_gb}GB ✓"
    
    # Check disk space
    available_gb=$(df / | awk 'NR==2 {printf "%.0f", $4/1024/1024}')
    if (( available_gb < 30 )); then
        log_error "Insufficient disk space: ${available_gb}GB (minimum 30GB required)"
        exit 1
    fi
    log_info "Disk space: ${available_gb}GB ✓"
    
    # Check for sudo privileges
    if ! sudo -n true 2>/dev/null; then
        log_error "This script requires sudo privileges"
        exit 1
    fi
    log_info "Sudo privileges ✓"
}

detect_existing_cuda() {
    log_step "Detecting existing CUDA installation..."
    
    # Check for nvidia-smi first
    if ! command -v nvidia-smi &> /dev/null; then
        log_error "nvidia-smi not found - NVIDIA drivers not installed"
        exit 1
    fi
    
    # Get CUDA driver version from nvidia-smi
    local driver_version=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader,nounits 2>/dev/null | head -1)
    log_info "NVIDIA Driver version: $driver_version"
    
    # Check for nvcc (CUDA compiler)
    if command -v nvcc &> /dev/null; then
        local cuda_version=$(nvcc --version | grep "release" | grep -o "V[0-9]\+\.[0-9]\+" | sed 's/V//')
        local cuda_path=$(which nvcc | sed 's|/bin/nvcc||')
        log_info "CUDA Toolkit found: $cuda_version at $cuda_path"
        export CUDA_HOME="$cuda_path"
        export CUDA_VERSION="$cuda_version"
    else
        # Try to find CUDA in common locations
        for cuda_dir in /usr/local/cuda* /opt/cuda* /usr/cuda*; do
            if [[ -d "$cuda_dir" && -f "$cuda_dir/bin/nvcc" ]]; then
                local cuda_version=$($cuda_dir/bin/nvcc --version | grep "release" | grep -o "V[0-9]\+\.[0-9]\+" | sed 's/V//')
                log_info "CUDA Toolkit found: $cuda_version at $cuda_dir"
                export CUDA_HOME="$cuda_dir"
                export CUDA_VERSION="$cuda_version"
                export PATH="$cuda_dir/bin:$PATH"
                break
            fi
        done
        
        if [[ -z "$CUDA_HOME" ]]; then
            log_error "CUDA toolkit not found. Please install CUDA first."
            exit 1
        fi
    fi
    
    # Verify CUDA works
    if [[ -f "$CUDA_HOME/bin/nvcc" ]]; then
        log_info "CUDA installation verified ✓"
        log_info "CUDA Home: $CUDA_HOME"
        log_info "CUDA Version: $CUDA_VERSION"
    else
        log_error "CUDA installation incomplete"
        exit 1
    fi
}

update_system() {
    log_step "Updating system packages..."
    
    sudo apt update -qq
    sudo apt upgrade -y -qq
    
    log_info "System updated"
}

install_essential_tools() {
    log_step "Installing essential build tools..."
    
    sudo apt install -y -qq \
        curl \
        wget \
        git \
        build-essential \
        cmake \
        ninja-build \
        pkg-config \
        ca-certificates \
        gnupg \
        lsb-release \
        software-properties-common \
        apt-transport-https
    
    log_info "Essential tools installed"
}

verify_gpu() {
    log_step "Verifying GPU setup..."
    
    if command -v nvidia-smi &> /dev/null; then
        gpu_info=$(nvidia-smi --query-gpu=name,memory.total --format=csv,noheader,nounits 2>/dev/null || echo "No GPU detected")
        log_info "GPU detected: $gpu_info"
        
        # Test CUDA
        if command -v nvcc &> /dev/null; then
            cuda_version=$(nvcc --version | grep "release" | grep -o "V[0-9]\+\.[0-9]\+" | sed 's/V//')
            log_info "CUDA version: $cuda_version"
        fi
    else
        log_warn "nvidia-smi not available - GPU drivers may need to be installed"
    fi
}

install_python_system_deps() {
    log_step "Installing Python and system dependencies..."
    
    sudo apt install -y -qq \
        python3 \
        python3-dev \
        python3-pip \
        python3-venv \
        python3-wheel \
        python3-setuptools
    
    # Upgrade pip
    python3 -m pip install --user --upgrade pip
    
    log_info "Python 3 system dependencies installed"
}

install_colmap_system_deps() {
    log_step "Installing COLMAP system dependencies..."
    
    sudo apt install -y -qq \
        libboost-program-options-dev \
        libboost-filesystem-dev \
        libboost-graph-dev \
        libboost-system-dev \
        libboost-test-dev \
        libeigen3-dev \
        libflann-dev \
        libfreeimage-dev \
        libmetis-dev \
        libgoogle-glog-dev \
        libgtest-dev \
        libsqlite3-dev \
        libglew-dev \
        qtbase5-dev \
        libqt5opengl5-dev \
        libcgal-dev \
        libceres-dev \
        libopencv-dev \
        libopencv-contrib-dev \
        libgl1-mesa-dev \
        libglu1-mesa-dev
    
    log_info "COLMAP system dependencies installed"
}

setup_directories() {
    log_step "Creating project directories..."
    
    mkdir -p ~/3d-reconstruction/{data,output,cache,logs}
    mkdir -p ~/3d-reconstruction/data/{images,models}
    mkdir -p ~/3d-reconstruction/output/{colmap,gaussian,results}
    
    log_info "Project directories created"
}

create_environment_profile() {
    log_step "Setting up environment profile..."
    
    # Create dynamic environment setup based on detected CUDA
    cat >> ~/.bashrc << EOF

# 3D Reconstruction Pipeline Environment (VM Compatible)
export CUDA_HOME=$CUDA_HOME
export PATH=\$CUDA_HOME/bin:\$PATH
export LD_LIBRARY_PATH=\$CUDA_HOME/lib64:\$LD_LIBRARY_PATH

# Optimization settings
export OMP_NUM_THREADS=16
export MKL_NUM_THREADS=16
export CUDA_VISIBLE_DEVICES=0

# Prevent CUDA initialization issues
export CUDA_LAUNCH_BLOCKING=0
export TORCH_CUDNN_V8_API_ENABLED=1

# Project paths
export RECONSTRUCTION_HOME=~/3d-reconstruction
export RECONSTRUCTION_DATA=\$RECONSTRUCTION_HOME/data
export RECONSTRUCTION_OUTPUT=\$RECONSTRUCTION_HOME/output
export RECONSTRUCTION_CACHE=\$RECONSTRUCTION_HOME/cache

EOF
    
    log_info "Environment profile created"
}

main() {
    print_banner
    
    log_info "Starting VM-compatible system setup for 3D reconstruction pipeline..."
    
    check_ubuntu_version
    check_system_requirements
    detect_existing_cuda
    update_system
    install_essential_tools
    verify_gpu
    install_python_system_deps
    install_colmap_system_deps
    setup_directories
    create_environment_profile
    
    echo ""
    log_info "VM-compatible system setup completed successfully!"
    echo ""
    echo -e "${YELLOW}Detected Configuration:${NC}"
    echo "  CUDA Home: $CUDA_HOME"
    echo "  CUDA Version: $CUDA_VERSION"
    echo "  GPU: $(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -1 || echo 'Not detected')"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo "  1. Source the environment: source ~/.bashrc"
    echo "  2. Run the build script: ./build-deps-vm.sh"
    echo ""
    echo -e "${YELLOW}Verify installation:${NC}"
    echo "  nvidia-smi"
    echo "  nvcc --version"
    echo "  python3 --version"
}

# Handle command line arguments
case "${1:-}" in
    --help|-h)
        echo "VM-Compatible System Setup for 3D Reconstruction Pipeline"
        echo "Usage: $0"
        echo ""
        echo "Features:"
        echo "  - Detects existing CUDA installation"
        echo "  - Uses VM's pre-installed drivers"
        echo "  - Installs only system dependencies"
        echo "  - No driver conflicts"
        echo ""
        exit 0
        ;;
    "")
        main
        ;;
    *)
        log_error "Unknown argument: $1"
        echo "Use --help for usage information"
        exit 1
        ;;
esac
