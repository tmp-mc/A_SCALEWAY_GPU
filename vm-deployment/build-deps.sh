#!/bin/bash
"""
Build Dependencies Script for 3D Reconstruction Pipeline
Compiles COLMAP with CUDA support and installs Python packages
"""

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step() { echo -e "${BLUE}[STEP]${NC} $1"; }

# Configuration
BUILD_DIR="$HOME/build"
INSTALL_PREFIX="/usr/local"
PYTHON_ENV="$HOME/3d-reconstruction/venv"

print_banner() {
    echo -e "${BLUE}================================================${NC}"
    echo -e "${BLUE}  Building Dependencies - COLMAP + Python      ${NC}"
    echo -e "${BLUE}  CUDA 12.6 + RTX 4090 Optimized Build        ${NC}"
    echo -e "${BLUE}================================================${NC}"
}

check_prerequisites() {
    log_step "Checking prerequisites..."
    
    # Check CUDA
    if ! command -v nvcc &> /dev/null; then
        log_error "CUDA not found. Run setup-system.sh first."
        exit 1
    fi
    
    cuda_version=$(nvcc --version | grep "release" | grep -o "V[0-9]\+\.[0-9]\+" | sed 's/V//')
    log_info "CUDA version: $cuda_version ✓"
    
    # Check GPU
    if command -v nvidia-smi &> /dev/null; then
        gpu_count=$(nvidia-smi --query-gpu=count --format=csv,noheader,nounits 2>/dev/null || echo "0")
        log_info "GPUs detected: $gpu_count ✓"
    fi
    
    # Check Python
    if ! command -v python3 &> /dev/null; then
        log_error "Python3 not found. Run setup-system.sh first."
        exit 1
    fi
    
    python_version=$(python3 --version | grep -o "[0-9]\+\.[0-9]\+")
    log_info "Python version: $python_version ✓"
}

setup_build_environment() {
    log_step "Setting up build environment..."
    
    # Create build directory
    mkdir -p "$BUILD_DIR"
    
    # Source environment variables
    export CUDA_HOME=/usr/local/cuda-12.6
    export PATH=$CUDA_HOME/bin:$PATH
    export LD_LIBRARY_PATH=$CUDA_HOME/lib64:$LD_LIBRARY_PATH
    export CUDA_ARCHITECTURES="89"  # RTX 4090 compute capability
    
    log_info "Build environment ready"
}

create_python_environment() {
    log_step "Creating Python virtual environment..."
    
    if [[ -d "$PYTHON_ENV" ]]; then
        log_info "Virtual environment already exists"
        return 0
    fi
    
    python3 -m venv "$PYTHON_ENV"
    source "$PYTHON_ENV/bin/activate"
    
    # Upgrade pip and essential tools
    pip install --upgrade pip setuptools wheel
    
    log_info "Python virtual environment created: $PYTHON_ENV"
}

install_pytorch() {
    log_step "Installing PyTorch with CUDA 12.6 support..."
    
    source "$PYTHON_ENV/bin/activate"
    
    # Install PyTorch for CUDA 12.6
    pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu126
    
    # Verify installation
    python3 -c "import torch; print(f'PyTorch {torch.__version__} with CUDA {torch.version.cuda}'); print(f'CUDA available: {torch.cuda.is_available()}')"
    
    log_info "PyTorch installed successfully"
}

install_gsplat() {
    log_step "Installing gsplat from source..."
    
    source "$PYTHON_ENV/bin/activate"
    
    # Install gsplat dependencies
    pip install ninja packaging
    
    # Install gsplat from GitHub for latest features
    pip install git+https://github.com/nerfstudio-project/gsplat.git
    
    # Verify installation
    python3 -c "import gsplat; print('gsplat installed successfully')"
    
    log_info "gsplat installed successfully"
}

build_colmap() {
    log_step "Building COLMAP with CUDA support..."
    
    # Check if COLMAP is already built
    if command -v colmap &> /dev/null && colmap --help | grep -q "CUDA enabled"; then
        log_info "COLMAP with CUDA already installed ✓"
        return 0
    fi
    
    cd "$BUILD_DIR"
    
    # Clone COLMAP if not present
    if [[ ! -d "colmap" ]]; then
        git clone https://github.com/colmap/colmap.git
    fi
    
    cd colmap
    git pull  # Get latest updates
    
    # Create build directory
    mkdir -p build && cd build
    
    # Configure with CMake - optimized for RTX 4090
    cmake .. \
        -GNinja \
        -DCMAKE_BUILD_TYPE=Release \
        -DCUDA_ENABLED=ON \
        -DCMAKE_CUDA_ARCHITECTURES=89 \
        -DGUI_ENABLED=ON \
        -DOPENGL_ENABLED=ON \
        -DCGAL_ENABLED=ON \
        -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" \
        -DCMAKE_CUDA_COMPILER=/usr/local/cuda-12.6/bin/nvcc
    
    # Build (parallel build based on CPU cores)
    ninja -j$(nproc)
    
    # Install
    sudo ninja install
    
    # Update library cache
    sudo ldconfig
    
    # Verify installation
    if colmap --help | grep -q "CUDA enabled"; then
        log_info "COLMAP built successfully with CUDA support"
    else
        log_warn "COLMAP built but CUDA support may not be enabled"
    fi
}

install_python_packages() {
    log_step "Installing additional Python packages..."
    
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
    
    # Utilities and progress bars
    pip install \
        tqdm \
        click \
        requests \
        urllib3
    
    log_info "Python packages installed"
}

create_activation_script() {
    log_step "Creating environment activation script..."
    
    cat > ~/3d-reconstruction/activate.sh << EOF
#!/bin/bash
# Activate 3D Reconstruction Pipeline Environment

# Activate Python virtual environment
source "$PYTHON_ENV/bin/activate"

# Set environment variables
export CUDA_HOME=/usr/local/cuda-12.6
export PATH=\$CUDA_HOME/bin:\$PATH
export LD_LIBRARY_PATH=\$CUDA_HOME/lib64:\$LD_LIBRARY_PATH

# Optimization settings
export OMP_NUM_THREADS=16
export MKL_NUM_THREADS=16
export CUDA_VISIBLE_DEVICES=0
export CUDA_LAUNCH_BLOCKING=0
export TORCH_CUDNN_V8_API_ENABLED=1

# Project paths
export RECONSTRUCTION_HOME=~/3d-reconstruction
export RECONSTRUCTION_DATA=\$RECONSTRUCTION_HOME/data
export RECONSTRUCTION_OUTPUT=\$RECONSTRUCTION_HOME/output
export RECONSTRUCTION_CACHE=\$RECONSTRUCTION_HOME/cache

echo "3D Reconstruction Pipeline Environment Activated"
echo "Python: \$(python --version)"
echo "PyTorch: \$(python -c 'import torch; print(torch.__version__)' 2>/dev/null || echo 'Not available')"
echo "CUDA: \$(python -c 'import torch; print(torch.version.cuda if torch.cuda.is_available() else "Not available")' 2>/dev/null)"
echo "COLMAP: \$(colmap --version 2>&1 | head -1 || echo 'Not available')"
echo "GPUs: \$(nvidia-smi --query-gpu=name --format=csv,noheader,nounits 2>/dev/null | wc -l || echo '0')"
EOF

    chmod +x ~/3d-reconstruction/activate.sh
    
    log_info "Activation script created: ~/3d-reconstruction/activate.sh"
}

run_verification_tests() {
    log_step "Running verification tests..."
    
    source "$PYTHON_ENV/bin/activate"
    
    echo "Testing installations:"
    
    # Test PyTorch
    echo -n "  PyTorch CUDA: "
    if python3 -c "import torch; assert torch.cuda.is_available()" 2>/dev/null; then
        echo "✓ Working"
    else
        echo "✗ Failed"
    fi
    
    # Test gsplat
    echo -n "  gsplat: "
    if python3 -c "import gsplat" 2>/dev/null; then
        echo "✓ Working"
    else
        echo "✗ Failed"
    fi
    
    # Test COLMAP
    echo -n "  COLMAP: "
    if colmap --help >/dev/null 2>&1; then
        echo "✓ Working"
    else
        echo "✗ Failed"
    fi
    
    # Test CUDA in COLMAP
    echo -n "  COLMAP CUDA: "
    if colmap --help 2>&1 | grep -q "CUDA enabled"; then
        echo "✓ Working"
    else
        echo "✗ Failed"
    fi
    
    # GPU Memory Test
    echo -n "  GPU Memory: "
    gpu_mem=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits 2>/dev/null | head -1)
    if [[ -n "$gpu_mem" ]] && [[ "$gpu_mem" -gt 8000 ]]; then
        echo "✓ ${gpu_mem}MB available"
    else
        echo "✗ Insufficient or not detected"
    fi
}

cleanup_build() {
    log_step "Cleaning up build files..."
    
    # Remove build directory to save space
    if [[ -d "$BUILD_DIR" ]]; then
        rm -rf "$BUILD_DIR"
        log_info "Build directory cleaned"
    fi
}

main() {
    print_banner
    
    log_info "Starting dependency build process..."
    
    check_prerequisites
    setup_build_environment
    create_python_environment
    install_pytorch
    install_gsplat
    build_colmap
    install_python_packages
    create_activation_script
    run_verification_tests
    cleanup_build
    
    echo ""
    log_info "Dependencies built successfully!"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo "  1. Activate environment: source ~/3d-reconstruction/activate.sh"
    echo "  2. Set up configuration: ./setup-env.sh"
    echo "  3. Run reconstruction: ./run-reconstruction.sh"
    echo ""
    echo -e "${YELLOW}Test installation:${NC}"
    echo "  source ~/3d-reconstruction/activate.sh"
    echo "  python3 -c 'import torch, gsplat; print(\"Ready for reconstruction!\")'"
    echo "  colmap --help"
}

case "${1:-}" in
    --help|-h)
        echo "Build Dependencies for 3D Reconstruction Pipeline"
        echo "Usage: $0 [--clean]"
        echo ""
        echo "Builds:"
        echo "  - COLMAP with CUDA 12.6 support"
        echo "  - PyTorch with CUDA support"
        echo "  - gsplat for Gaussian splatting"
        echo "  - Python scientific packages"
        echo ""
        echo "Options:"
        echo "  --clean    Clean build directory after successful build"
        exit 0
        ;;
    --clean)
        BUILD_CLEAN=true
        main
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
