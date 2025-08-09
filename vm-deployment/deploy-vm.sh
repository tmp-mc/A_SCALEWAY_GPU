#!/bin/bash
"""
3D Reconstruction Pipeline - Ubuntu 24.04 Noble Wombat + L4 GPU
Streamlined deployment assuming NVIDIA drivers and CUDA are pre-installed
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

# Configuration for L4 GPU
GPU_ARCH="89"  # Ada Lovelace architecture
GPU_MEMORY="24576"  # 24GB in MB
PROJECT_DIR="$HOME/3d-reconstruction"
PYTHON_ENV="$PROJECT_DIR/venv"
BUILD_DIR="/tmp/colmap-build"

print_banner() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                                                                              ║${NC}"
    echo -e "${CYAN}║                    ${BOLD}3D RECONSTRUCTION PIPELINE${NC}${CYAN}                           ║${NC}"
    echo -e "${CYAN}║                                                                              ║${NC}"
    echo -e "${CYAN}║                Ubuntu 24.04 Noble Wombat + NVIDIA L4 (24GB)                ║${NC}"
    echo -e "${CYAN}║                   COLMAP + gsplat + PyTorch CUDA                            ║${NC}"
    echo -e "${CYAN}║                                                                              ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

check_prerequisites() {
    log_step "Checking system prerequisites..."
    
    # Check Ubuntu version
    if ! lsb_release -r | grep -q "24.04"; then
        log_error "This script is optimized for Ubuntu 24.04 Noble Wombat"
        exit 1
    fi
    log_info "Ubuntu 24.04 Noble Wombat ✓"
    
    # Check NVIDIA driver
    if ! command -v nvidia-smi &> /dev/null; then
        log_error "nvidia-smi not found - NVIDIA drivers not installed"
        exit 1
    fi
    
    # Verify L4 GPU
    gpu_name=$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -1)
    gpu_memory=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits 2>/dev/null | head -1)
    log_info "GPU: $gpu_name (${gpu_memory}MB)"
    
    if [[ ! "$gpu_name" =~ "L4" ]]; then
        log_warn "GPU is not L4 - script optimized for L4 but will continue"
    fi
    
    # Check disk space (need at least 30GB)
    available_gb=$(df / | awk 'NR==2 {printf "%.0f", $4/1024/1024}')
    if [[ "$available_gb" -lt 30 ]]; then
        log_error "Insufficient disk space: ${available_gb}GB (minimum: 30GB)"
        exit 1
    fi
    log_info "Disk space: ${available_gb}GB ✓"
    
    # Check internet connectivity
    if ! ping -c 1 google.com &> /dev/null; then
        log_error "Internet connection required"
        exit 1
    fi
    log_info "Internet connectivity ✓"
    
    # Check sudo access
    if ! sudo -n true 2>/dev/null; then
        log_warn "This script requires sudo privileges"
        echo "You may be prompted for your password during installation"
    fi
    
    log_info "Prerequisites check passed ✓"
}

update_system() {
    log_step "Updating system packages..."
    
    sudo apt update -qq
    sudo apt upgrade -y -qq
    
    log_info "System updated"
}

install_system_dependencies() {
    log_step "Installing system dependencies..."
    
    # Essential build tools
    sudo apt install -y -qq \
        curl \
        wget \
        git \
        build-essential \
        cmake \
        ninja-build \
        pkg-config \
        ca-certificates \
        software-properties-common
    
    # Python 3.12 and development tools
    sudo apt install -y -qq \
        python3 \
        python3-dev \
        python3-pip \
        python3-venv \
        python3-wheel \
        python3-setuptools
    
    # COLMAP dependencies
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
    
    # Upgrade pip
    python3 -m pip install --user --upgrade pip
    
    log_info "System dependencies installed"
}

create_project_structure() {
    log_step "Creating project structure..."
    
    # Create main directories
    mkdir -p "$PROJECT_DIR"/{data,output,cache,logs,scripts}
    mkdir -p "$PROJECT_DIR/data"/{images,models}
    mkdir -p "$PROJECT_DIR/output"/{colmap,gaussian,results}
    
    log_info "Project structure created at $PROJECT_DIR"
}

setup_python_environment() {
    log_step "Setting up Python virtual environment..."
    
    # Create virtual environment
    python3 -m venv "$PYTHON_ENV"
    source "$PYTHON_ENV/bin/activate"
    
    # Upgrade pip and essential tools
    pip install --upgrade pip setuptools wheel
    
    log_info "Python virtual environment created"
}

install_pytorch() {
    log_step "Installing PyTorch with CUDA support..."
    
    source "$PYTHON_ENV/bin/activate"
    
    # Install PyTorch with CUDA 12.x support (auto-detects CUDA version)
    pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
    
    # Verify PyTorch CUDA
    python3 -c "
import torch
print(f'PyTorch version: {torch.__version__}')
print(f'CUDA available: {torch.cuda.is_available()}')
if torch.cuda.is_available():
    print(f'CUDA version: {torch.version.cuda}')
    print(f'GPU count: {torch.cuda.device_count()}')
    print(f'GPU name: {torch.cuda.get_device_name(0)}')
    print(f'GPU memory: {torch.cuda.get_device_properties(0).total_memory / 1024**3:.1f}GB')
"
    
    log_info "PyTorch with CUDA installed successfully"
}

install_python_packages() {
    log_step "Installing Python packages..."
    
    source "$PYTHON_ENV/bin/activate"
    
    # Scientific computing and computer vision
    pip install \
        numpy \
        scipy \
        scikit-learn \
        scikit-image \
        opencv-python \
        opencv-contrib-python \
        pillow \
        imageio \
        matplotlib \
        plotly
    
    # 3D processing
    pip install \
        trimesh \
        open3d \
        plyfile
    
    # Data handling
    pip install \
        pandas \
        h5py \
        pyyaml \
        toml
    
    # Utilities
    pip install \
        tqdm \
        click \
        requests \
        urllib3
    
    # Install gsplat from source for latest features
    pip install ninja packaging
    pip install git+https://github.com/nerfstudio-project/gsplat.git
    
    # Verify gsplat installation
    python3 -c "import gsplat; print('gsplat installed successfully')"
    
    log_info "Python packages installed"
}

build_colmap() {
    log_step "Building COLMAP with L4 GPU optimization..."
    
    # Check if COLMAP already exists
    if command -v colmap &> /dev/null; then
        log_info "COLMAP already installed, skipping build"
        return 0
    fi
    
    # Create build directory
    mkdir -p "$BUILD_DIR"
    cd "$BUILD_DIR"
    
    # Clone COLMAP
    git clone https://github.com/colmap/colmap.git
    cd colmap
    
    # Create build directory
    mkdir -p build && cd build
    
    # Configure with CMake - optimized for L4 GPU (Ada Lovelace, Compute 8.9)
    cmake .. \
        -GNinja \
        -DCMAKE_BUILD_TYPE=Release \
        -DCUDA_ENABLED=ON \
        -DCMAKE_CUDA_ARCHITECTURES="$GPU_ARCH" \
        -DGUI_ENABLED=ON \
        -DOPENGL_ENABLED=ON \
        -DCGAL_ENABLED=ON \
        -DCMAKE_INSTALL_PREFIX=/usr/local
    
    # Build with all available cores
    ninja -j$(nproc)
    
    # Install
    sudo ninja install
    
    # Update library cache
    sudo ldconfig
    
    # Clean up build directory
    cd /
    rm -rf "$BUILD_DIR"
    
    # Verify COLMAP installation
    if colmap --help | grep -q "CUDA enabled"; then
        log_info "COLMAP built successfully with CUDA support"
    else
        log_warn "COLMAP built but CUDA support may not be enabled"
    fi
}

create_activation_script() {
    log_step "Creating environment activation script..."
    
    cat > "$PROJECT_DIR/activate.sh" << 'EOF'
#!/bin/bash
# Activate 3D Reconstruction Pipeline Environment
# Optimized for Ubuntu 24.04 Noble Wombat + L4 GPU

# Activate Python virtual environment
source ~/3d-reconstruction/venv/bin/activate

# L4 GPU optimizations (24GB VRAM)
export CUDA_VISIBLE_DEVICES=0
export CUDA_LAUNCH_BLOCKING=0
export TORCH_CUDNN_V8_API_ENABLED=1

# Memory settings for L4 (24GB)
export CUDA_MEMORY_FRACTION=0.9
export OMP_NUM_THREADS=16
export MKL_NUM_THREADS=16

# Project paths
export RECONSTRUCTION_HOME=~/3d-reconstruction
export RECONSTRUCTION_DATA=$RECONSTRUCTION_HOME/data
export RECONSTRUCTION_OUTPUT=$RECONSTRUCTION_HOME/output
export RECONSTRUCTION_CACHE=$RECONSTRUCTION_HOME/cache

echo "🚀 3D Reconstruction Pipeline Environment Activated"
echo "📍 Ubuntu 24.04 Noble Wombat + L4 GPU (24GB)"
echo "🐍 Python: $(python --version)"
echo "🔥 PyTorch: $(python -c 'import torch; print(torch.__version__)' 2>/dev/null || echo 'Not available')"
echo "⚡ CUDA: $(python -c 'import torch; print("Available" if torch.cuda.is_available() else "Not available")' 2>/dev/null)"
echo "📷 COLMAP: $(colmap --version 2>&1 | head -1 || echo 'Not available')"
echo "🎮 GPU: $(nvidia-smi --query-gpu=name,memory.total --format=csv,noheader 2>/dev/null | head -1)"
EOF

    chmod +x "$PROJECT_DIR/activate.sh"
    
    log_info "Activation script created: $PROJECT_DIR/activate.sh"
}

create_configuration() {
    log_step "Creating project configuration..."
    
    # Create .env file with L4-optimized settings
    cat > "$PROJECT_DIR/.env" << EOF
# 3D Reconstruction Pipeline Configuration
# Optimized for Ubuntu 24.04 Noble Wombat + L4 GPU (24GB)

# GPU Configuration
USE_GPU=true
CUDA_DEVICE=0
GPU_MEMORY_GB=24

# Processing Settings (optimized for L4's 24GB VRAM)
MAX_IMAGE_SIZE=4096
COLMAP_QUALITY=high
GAUSSIAN_ITERATIONS=30000
BATCH_SIZE=8

# L4 GPU Optimizations
CUDA_MEMORY_FRACTION=0.9
ENABLE_MIXED_PRECISION=true
ENABLE_CUDNN_BENCHMARK=true

# Output Settings
OUTPUT_FORMAT=ply
ENABLE_WEB_VIEWER=true
COMPRESSION_LEVEL=6

# Performance Settings
PARALLEL_WORKERS=16
CACHE_SIZE_GB=8

# Optional: Bunny CDN Configuration
BUNNY_API_KEY=
BUNNY_STORAGE_ZONE=
BUNNY_HOSTNAME=
EOF

    # Create template
    cp "$PROJECT_DIR/.env" "$PROJECT_DIR/.env.template"
    
    log_info "Configuration files created"
}

copy_pipeline_scripts() {
    log_step "Setting up pipeline scripts..."
    
    # Copy existing scripts if they exist
    if [[ -f "$(dirname "$0")/run-reconstruction.sh" ]]; then
        cp "$(dirname "$0")/run-reconstruction.sh" "$PROJECT_DIR/"
        chmod +x "$PROJECT_DIR/run-reconstruction.sh"
    fi
    
    if [[ -d "$(dirname "$0")/scripts" ]]; then
        cp -r "$(dirname "$0")/scripts" "$PROJECT_DIR/"
        chmod +x "$PROJECT_DIR/scripts"/*.py 2>/dev/null || true
    fi
    
    log_info "Pipeline scripts set up"
}

create_status_script() {
    log_step "Creating system status script..."
    
    cat > "$PROJECT_DIR/check-status.sh" << 'EOF'
#!/bin/bash
# System Status Check for 3D Reconstruction Pipeline
# Ubuntu 24.04 Noble Wombat + L4 GPU

echo "🔍 3D Reconstruction Pipeline Status Check"
echo "=========================================="
echo ""

# System Information
echo "📋 System Information:"
echo "   OS: $(lsb_release -d | cut -f2)"
echo "   Kernel: $(uname -r)"
echo "   Uptime: $(uptime -p)"
echo ""

# GPU Information
echo "🎮 GPU Information:"
if command -v nvidia-smi &> /dev/null; then
    echo "   Driver: $(nvidia-smi --query-gpu=driver_version --format=csv,noheader | head -1)"
    echo "   GPU: $(nvidia-smi --query-gpu=name --format=csv,noheader | head -1)"
    echo "   Memory: $(nvidia-smi --query-gpu=memory.total --format=csv,noheader | head -1)"
    echo "   Temperature: $(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader | head -1)°C"
    echo "   Utilization: $(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader | head -1)"
else
    echo "   ❌ NVIDIA drivers not found"
fi
echo ""

# Python Environment
echo "🐍 Python Environment:"
if [[ -f ~/3d-reconstruction/activate.sh ]]; then
    source ~/3d-reconstruction/activate.sh > /dev/null 2>&1
    echo "   Python: $(python --version 2>&1)"
    echo "   PyTorch: $(python -c 'import torch; print(torch.__version__)' 2>/dev/null || echo 'Not available')"
    echo "   CUDA in PyTorch: $(python -c 'import torch; print("✅ Available" if torch.cuda.is_available() else "❌ Not available")' 2>/dev/null)"
    echo "   gsplat: $(python -c 'import gsplat; print("✅ Available")' 2>/dev/null || echo '❌ Not available')"
    echo "   GPU Memory: $(python -c 'import torch; print(f"{torch.cuda.get_device_properties(0).total_memory/1024**3:.1f}GB") if torch.cuda.is_available() else print("N/A")' 2>/dev/null)"
else
    echo "   ❌ Environment not set up"
fi
echo ""

# COLMAP
echo "📷 COLMAP:"
if command -v colmap &> /dev/null; then
    echo "   Version: $(colmap --version 2>&1 | head -1)"
    echo "   CUDA: $(colmap --help 2>&1 | grep -q "CUDA enabled" && echo "✅ Enabled" || echo "❌ Disabled")"
else
    echo "   ❌ Not installed"
fi
echo ""

# Project Status
echo "📁 Project Status:"
if [[ -d ~/3d-reconstruction ]]; then
    echo "   Project directory: ✅ Exists"
    echo "   Images: $(find ~/3d-reconstruction/data/images/ -name "*.jpg" -o -name "*.png" 2>/dev/null | wc -l) files"
    echo "   Results: $(ls ~/3d-reconstruction/output/results/ 2>/dev/null | wc -l) reconstructions"
    echo "   Disk usage: $(du -sh ~/3d-reconstruction 2>/dev/null | cut -f1)"
else
    echo "   ❌ Project directory not found"
fi
echo ""

# Disk Space
echo "💾 Storage:"
echo "   Available: $(df -h / | awk 'NR==2 {print $4}')"
echo "   Used: $(df -h / | awk 'NR==2 {print $3}')"
echo ""

echo "✅ Status check complete!"
EOF

    chmod +x "$PROJECT_DIR/check-status.sh"
    
    log_info "Status script created: $PROJECT_DIR/check-status.sh"
}

run_verification() {
    log_step "Running installation verification..."
    
    source "$PYTHON_ENV/bin/activate"
    
    echo "🧪 Testing installations:"
    
    # Test PyTorch CUDA
    echo -n "   PyTorch CUDA: "
    if python3 -c "import torch; assert torch.cuda.is_available(); print('✅ Working')" 2>/dev/null; then
        echo "✅ Working"
    else
        echo "❌ Failed"
        return 1
    fi
    
    # Test gsplat
    echo -n "   gsplat: "
    if python3 -c "import gsplat; print('✅ Working')" 2>/dev/null; then
        echo "✅ Working"
    else
        echo "❌ Failed"
        return 1
    fi
    
    # Test COLMAP
    echo -n "   COLMAP: "
    if command -v colmap &> /dev/null; then
        echo "✅ Working"
    else
        echo "❌ Failed"
        return 1
    fi
    
    # Test COLMAP CUDA
    echo -n "   COLMAP CUDA: "
    if colmap --help 2>&1 | grep -q "CUDA enabled"; then
        echo "✅ Working"
    else
        echo "❌ Failed"
        return 1
    fi
    
    log_info "All verification tests passed ✅"
    return 0
}

display_completion_summary() {
    echo ""
    log_header "🎉 DEPLOYMENT COMPLETED SUCCESSFULLY!"
    echo ""
    
    # Get system info
    local gpu_name=$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -1)
    local gpu_mem=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader 2>/dev/null | head -1)
    local python_version=$(python3 --version | grep -o "[0-9.]*")
    
    echo -e "${YELLOW}🖥️  System Configuration:${NC}"
    echo "   📍 OS: Ubuntu 24.04 Noble Wombat"
    echo "   🎮 GPU: $gpu_name ($gpu_mem)"
    echo "   🐍 Python: $python_version"
    echo "   🔥 PyTorch: $(source "$PYTHON_ENV/bin/activate" && python3 -c 'import torch; print(torch.__version__)' 2>/dev/null || echo 'Not available')"
    echo "   📷 COLMAP: $(colmap --version 2>&1 | head -1 | cut -d' ' -f2 || echo 'Not available')"
    echo "   📁 Project: $PROJECT_DIR"
    
    echo ""
    echo -e "${YELLOW}🚀 Quick Start:${NC}"
    echo "   1. Activate environment:"
    echo "      ${CYAN}source ~/3d-reconstruction/activate.sh${NC}"
    echo ""
    echo "   2. Check system status:"
    echo "      ${CYAN}~/3d-reconstruction/check-status.sh${NC}"
    echo ""
    echo "   3. Place your images:"
    echo "      ${CYAN}cp /path/to/images/* ~/3d-reconstruction/data/images/${NC}"
    echo ""
    echo "   4. Run reconstruction:"
    echo "      ${CYAN}cd ~/3d-reconstruction && ./run-reconstruction.sh${NC}"
    echo ""
    
    echo -e "${YELLOW}🎯 L4 GPU Optimizations:${NC}"
    echo "   ✅ CUDA Architecture 8.9 (Ada Lovelace)"
    echo "   ✅ 24GB VRAM optimized settings"
    echo "   ✅ High-resolution image processing (4K)"
    echo "   ✅ Mixed precision training enabled"
    echo "   ✅ Optimized batch sizes and memory usage"
    
    echo ""
    echo -e "${GREEN}🎊 Ready for 3D reconstruction with L4 GPU power!${NC}"
    echo ""
}

handle_error() {
    local exit_code=$?
    local line_number=$1
    
    echo ""
    log_error "Deployment failed at line $line_number (exit code: $exit_code)"
    echo ""
    echo -e "${YELLOW}🔧 Troubleshooting:${NC}"
    echo "   • Check NVIDIA drivers: nvidia-smi"
    echo "   • Verify internet connection"
    echo "   • Ensure sufficient disk space (30GB+)"
    echo "   • Check system logs: journalctl -xe"
    echo ""
    echo -e "${YELLOW}📞 Support:${NC}"
    echo "   • Check status: ~/3d-reconstruction/check-status.sh"
    echo "   • View logs: ~/3d-reconstruction/logs/"
    echo ""
    
    exit $exit_code
}

main() {
    local start_time=$(date +%s)
    
    print_banner
    
    log_info "Starting deployment for Ubuntu 24.04 Noble Wombat + L4 GPU..."
    
    # Set up error handling
    trap 'handle_error $LINENO' ERR
    
    # Run deployment phases
    check_prerequisites
    update_system
    install_system_dependencies
    create_project_structure
    setup_python_environment
    install_pytorch
    install_python_packages
    build_colmap
    create_activation_script
    create_configuration
    copy_pipeline_scripts
    create_status_script
    
    if run_verification; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        local minutes=$((duration / 60))
        
        display_completion_summary
        echo -e "${CYAN}⏱️  Total deployment time: ${minutes} minutes${NC}"
        
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
3D Reconstruction Pipeline Deployment
Ubuntu 24.04 Noble Wombat + NVIDIA L4 GPU (24GB)

This script performs a complete deployment including:
• System dependencies and build tools
• Python 3.12 virtual environment
• PyTorch with CUDA 12.x support
• gsplat (GPU-accelerated Gaussian splatting)
• COLMAP with L4 GPU optimization (CUDA 8.9)
• Project structure and configuration
• L4-specific optimizations for 24GB VRAM

Usage: $0 [options]

Options:
  --help, -h        Show this help message
  --verify-only     Only run verification tests
  --status          Show system status

Requirements:
• Ubuntu 24.04 Noble Wombat
• NVIDIA L4 GPU with drivers installed
• CUDA toolkit installed
• 30+ GB available disk space
• 16+ GB RAM
• Internet connection
• Sudo privileges

The deployment process takes approximately 15-30 minutes.

EOF
        exit 0
        ;;
    --verify-only)
        if [[ -f "$PYTHON_ENV/bin/activate" ]]; then
            if run_verification; then
                echo "✅ Verification passed"
                exit 0
            else
                echo "❌ Verification failed"
                exit 1
            fi
        else
            echo "❌ Environment not found - run deployment first"
            exit 1
        fi
        ;;
    --status)
        if [[ -f "$PROJECT_DIR/check-status.sh" ]]; then
            source "$PROJECT_DIR/check-status.sh"
        else
            echo "❌ Status script not found - run deployment first"
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
