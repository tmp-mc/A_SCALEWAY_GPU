#!/bin/bash
"""
VM-Compatible Build Dependencies Script for 3D Reconstruction Pipeline
Auto-detects CUDA version and installs compatible packages
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
    echo -e "${BLUE}  Building Dependencies - VM Compatible        ${NC}"
    echo -e "${BLUE}  Auto-detecting CUDA + PyTorch Installation   ${NC}"
    echo -e "${BLUE}================================================${NC}"
}

detect_cuda_configuration() {
    log_step "Detecting CUDA configuration..."
    
    # Check for nvidia-smi first
    if ! command -v nvidia-smi &> /dev/null; then
        log_error "nvidia-smi not found - NVIDIA drivers not installed"
        exit 1
    fi
    
    # Check for nvcc (CUDA compiler)
    if command -v nvcc &> /dev/null; then
        CUDA_VERSION=$(nvcc --version | grep "release" | grep -o "V[0-9]\+\.[0-9]\+" | sed 's/V//')
        CUDA_HOME=$(which nvcc | sed 's|/bin/nvcc||')
    else
        # Try to find CUDA in common locations
        for cuda_dir in /usr/local/cuda* /opt/cuda* /usr/cuda*; do
            if [[ -d "$cuda_dir" && -f "$cuda_dir/bin/nvcc" ]]; then
                CUDA_VERSION=$($cuda_dir/bin/nvcc --version | grep "release" | grep -o "V[0-9]\+\.[0-9]\+" | sed 's/V//')
                CUDA_HOME="$cuda_dir"
                export PATH="$cuda_dir/bin:$PATH"
                break
            fi
        done
        
        if [[ -z "$CUDA_HOME" ]]; then
            log_error "CUDA toolkit not found. Run setup-system-vm.sh first."
            exit 1
        fi
    fi
    
    # Determine PyTorch CUDA version string
    CUDA_MAJOR=$(echo $CUDA_VERSION | cut -d. -f1)
    CUDA_MINOR=$(echo $CUDA_VERSION | cut -d. -f2)
    
    if [[ "$CUDA_MAJOR" == "12" ]]; then
        if [[ "$CUDA_MINOR" -ge "1" ]]; then
            PYTORCH_CUDA="cu121"
        else
            PYTORCH_CUDA="cu118"
        fi
    elif [[ "$CUDA_MAJOR" == "11" ]]; then
        if [[ "$CUDA_MINOR" -ge "8" ]]; then
            PYTORCH_CUDA="cu118"
        else
            PYTORCH_CUDA="cu117"
        fi
    else
        log_warn "Unsupported CUDA version: $CUDA_VERSION, defaulting to CPU-only PyTorch"
        PYTORCH_CUDA="cpu"
    fi
    
    # Determine GPU compute capability for COLMAP
    if command -v nvidia-smi &> /dev/null; then
        GPU_NAME=$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -1)
        
        # Map common GPUs to compute capabilities
        case "$GPU_NAME" in
            *"RTX 4090"*|*"RTX 4080"*|*"RTX 4070"*) CUDA_ARCH="89" ;;
            *"RTX 3090"*|*"RTX 3080"*|*"RTX 3070"*) CUDA_ARCH="86" ;;
            *"RTX 2080"*|*"RTX 2070"*) CUDA_ARCH="75" ;;
            *"GTX 1080"*|*"GTX 1070"*) CUDA_ARCH="61" ;;
            *"Tesla V100"*) CUDA_ARCH="70" ;;
            *"Tesla T4"*) CUDA_ARCH="75" ;;
            *"A100"*) CUDA_ARCH="80" ;;
            *) CUDA_ARCH="75" ;; # Safe default
        esac
    else
        CUDA_ARCH="75" # Safe default
    fi
    
    log_info "CUDA Version: $CUDA_VERSION"
    log_info "CUDA Home: $CUDA_HOME"
    log_info "PyTorch CUDA: $PYTORCH_CUDA"
    log_info "GPU: $GPU_NAME"
    log_info "CUDA Architecture: $CUDA_ARCH"
}

check_prerequisites() {
    log_step "Checking prerequisites..."
    
    # Check CUDA
    if [[ -z "$CUDA_HOME" ]] || [[ -z "$CUDA_VERSION" ]]; then
        log_error "CUDA configuration not detected. Run setup-system-vm.sh first."
        exit 1
    fi
    
    log_info "CUDA version: $CUDA_VERSION ✓"
    
    # Check GPU
    if command -v nvidia-smi &> /dev/null; then
        gpu_count=$(nvidia-smi --query-gpu=count --format=csv,noheader,nounits 2>/dev/null || echo "0")
        log_info "GPUs detected: $gpu_count ✓"
    fi
    
    # Check Python
    if ! command -v python3 &> /dev/null; then
        log_error "Python3 not found. Run setup-system-vm.sh first."
        exit 1
    fi
    
    python_version=$(python3 --version | grep -o "[0-9]\+\.[0-9]\+")
    log_info "Python version: $python_version ✓"
}

setup_build_environment() {
    log_step "Setting up build environment..."
    
    # Create build directory
    mkdir -p "$BUILD_DIR"
    
    # Set environment variables
    export CUDA_HOME="$CUDA_HOME"
    export PATH="$CUDA_HOME/bin:$PATH"
    export LD_LIBRARY_PATH="$CUDA_HOME/lib64:$LD_LIBRARY_PATH"
    export CUDA_ARCHITECTURES="$CUDA_ARCH"
    
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
    log_step "Installing PyTorch with CUDA $CUDA_VERSION support..."
    
    source "$PYTHON_ENV/bin/activate"
    
    # Install PyTorch based on detected CUDA version
    if [[ "$PYTORCH_CUDA" == "cpu" ]]; then
        log_warn "Installing CPU-only PyTorch (CUDA not supported)"
        pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu
    else
        log_info "Installing PyTorch for CUDA $PYTORCH_CUDA"
        case "$PYTORCH_CUDA" in
            "cu121")
                pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
                ;;
            "cu118")
                pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
                ;;
            "cu117")
                pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu117
                ;;
            *)
                log_warn "Unknown CUDA version, installing latest stable PyTorch"
                pip install torch torchvision torchaudio
                ;;
        esac
    fi
    
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
    
    # Configure with CMake - using detected CUDA architecture
    cmake .. \
        -GNinja \
        -DCMAKE_BUILD_TYPE=Release \
        -DCUDA_ENABLED=ON \
        -DCMAKE_CUDA_ARCHITECTURES="$CUDA_ARCH" \
        -DGUI_ENABLED=ON \
        -DOPENGL_ENABLED=ON \
        -DCGAL_ENABLED=ON \
        -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" \
        -DCMAKE_CUDA_COMPILER="$CUDA_HOME/bin/nvcc"
    
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
# Activate 3D Reconstruction Pipeline Environment (VM Compatible)

# Activate Python virtual environment
source "$PYTHON_ENV/bin/activate"

# Set environment variables (dynamic based on detected CUDA)
export CUDA_HOME="$CUDA_HOME"
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

echo "3D Reconstruction Pipeline Environment Activated (VM Compatible)"
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
        echo "✗ Failed (may be CPU-only)"
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
    if [[ -n "$gpu_mem" ]] && [[ "$gpu_mem" -gt 4000 ]]; then
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
    
    log_info "Starting VM-compatible dependency build process..."
    
    detect_cuda_configuration
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
    log_info "VM-compatible dependencies built successfully!"
    echo ""
    echo -e "${YELLOW}Configuration Summary:${NC}"
    echo "  CUDA Version: $CUDA_VERSION"
    echo "  PyTorch CUDA: $PYTORCH_CUDA"
    echo "  GPU Architecture: $CUDA_ARCH"
    echo "  GPU: $GPU_NAME"
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
        echo "VM-Compatible Build Dependencies for 3D Reconstruction Pipeline"
        echo "Usage: $0 [--clean]"
        echo ""
        echo "Features:"
        echo "  - Auto-detects CUDA version"
        echo "  - Installs compatible PyTorch"
        echo "  - Builds COLMAP with detected GPU architecture"
        echo "  - No hardcoded CUDA versions"
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
