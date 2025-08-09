#!/bin/bash
"""
System Setup Script for 3D Reconstruction Pipeline
Installs CUDA 12.6, system dependencies, and GPU drivers on Ubuntu 24.04
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
    echo -e "${BLUE}  3D Reconstruction Pipeline - System Setup    ${NC}"
    echo -e "${BLUE}  Ubuntu 24.04 + CUDA 12.6 + RTX 4090 Support ${NC}"
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

install_cuda() {
    log_step "Installing CUDA 12.6..."
    
    # Check if CUDA is already installed
    if command -v nvcc &> /dev/null && nvcc --version | grep -q "12.6"; then
        log_info "CUDA 12.6 already installed ✓"
        return 0
    fi
    
    # Download and install CUDA keyring
    wget -q https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/cuda-keyring_1.1-1_all.deb
    sudo dpkg -i cuda-keyring_1.1-1_all.deb
    rm cuda-keyring_1.1-1_all.deb
    
    # Update package lists
    sudo apt update -qq
    
    # Install CUDA toolkit
    sudo apt install -y cuda-toolkit-12-6 cuda-drivers
    
    # Set up environment
    echo 'export PATH=/usr/local/cuda-12.6/bin:$PATH' >> ~/.bashrc
    echo 'export LD_LIBRARY_PATH=/usr/local/cuda-12.6/lib64:$LD_LIBRARY_PATH' >> ~/.bashrc
    export PATH=/usr/local/cuda-12.6/bin:$PATH
    export LD_LIBRARY_PATH=/usr/local/cuda-12.6/lib64:$LD_LIBRARY_PATH
    
    log_info "CUDA 12.6 installed"
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
        log_warn "Run 'sudo ubuntu-drivers autoinstall' and reboot if needed"
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
    
    cat >> ~/.bashrc << 'EOF'

# 3D Reconstruction Pipeline Environment
export CUDA_HOME=/usr/local/cuda-12.6
export PATH=$CUDA_HOME/bin:$PATH
export LD_LIBRARY_PATH=$CUDA_HOME/lib64:$LD_LIBRARY_PATH

# Optimization settings for RTX 4090
export OMP_NUM_THREADS=16
export MKL_NUM_THREADS=16
export CUDA_VISIBLE_DEVICES=0

# Prevent CUDA initialization issues
export CUDA_LAUNCH_BLOCKING=0
export TORCH_CUDNN_V8_API_ENABLED=1

# Project paths
export RECONSTRUCTION_HOME=~/3d-reconstruction
export RECONSTRUCTION_DATA=$RECONSTRUCTION_HOME/data
export RECONSTRUCTION_OUTPUT=$RECONSTRUCTION_HOME/output
export RECONSTRUCTION_CACHE=$RECONSTRUCTION_HOME/cache

EOF
    
    log_info "Environment profile created"
}

main() {
    print_banner
    
    log_info "Starting system setup for 3D reconstruction pipeline..."
    
    check_ubuntu_version
    check_system_requirements
    update_system
    install_essential_tools
    install_cuda
    verify_gpu
    install_python_system_deps
    install_colmap_system_deps
    setup_directories
    create_environment_profile
    
    echo ""
    log_info "System setup completed successfully!"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo "  1. Source the environment: source ~/.bashrc"
    echo "  2. Reboot if GPU drivers were installed: sudo reboot"
    echo "  3. Run the build script: ./build-deps.sh"
    echo ""
    echo -e "${YELLOW}Verify installation:${NC}"
    echo "  nvidia-smi"
    echo "  nvcc --version"
    echo "  python3 --version"
}

# Handle command line arguments
case "${1:-}" in
    --help|-h)
        echo "System Setup for 3D Reconstruction Pipeline"
        echo "Usage: $0"
        echo ""
        echo "Installs:"
        echo "  - CUDA 12.6 toolkit"
        echo "  - Python 3.11+ with development tools" 
        echo "  - System dependencies for COLMAP"
        echo "  - GPU drivers (if needed)"
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
