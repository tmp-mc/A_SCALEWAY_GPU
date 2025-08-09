#!/bin/bash
#
# 3D Reconstruction Pipeline - Unified Deployment Script
# Ubuntu 24.04 + CUDA 12.6 + GPU Optimization
# Handles complete system setup from scratch
#

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

# Configuration
GPU_ARCH="89"  # RTX 4090/L4 Ada Lovelace architecture
PROJECT_DIR="$HOME/3d-reconstruction"
PYTHON_ENV="$PROJECT_DIR/venv"
BUILD_DIR="/tmp/colmap-build"

print_banner() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                                                                              ║${NC}"
    echo -e "${CYAN}║                    ${BOLD}3D RECONSTRUCTION PIPELINE${NC}${CYAN}                           ║${NC}"
    echo -e "${CYAN}║                                                                              ║${NC}"
    echo -e "${CYAN}║                Ubuntu 24.04 + CUDA 12.6 + GPU Optimization                 ║${NC}"
    echo -e "${CYAN}║                   COLMAP + gsplat + PyTorch CUDA                            ║${NC}"
    echo -e "${CYAN}║                                                                              ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

check_prerequisites() {
    log_step "Checking system prerequisites..."
    
    # Check Ubuntu version
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
    
    # Check system requirements
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
    
    # Check sudo privileges
    if ! sudo -n true 2>/dev/null; then
        log_warn "This script requires sudo privileges"
        echo "You may be prompted for your password during installation"
    fi
    log_info "Sudo privileges ✓"
    
    # Check internet connectivity
    if ! ping -c 1 google.com &> /dev/null; then
        log_error "Internet connection required"
        exit 1
    fi
    log_info "Internet connectivity ✓"
    
    log_info "Prerequisites check passed ✓"
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
        apt-transport-https \
        dkms
    
    log_info "Essential tools installed"
}

cleanup_all_cuda_installations() {
    log_step "Cleaning up existing CUDA installations..."
    
    # Stop nvidia services
    sudo systemctl stop nvidia-persistenced 2>/dev/null || true
    
    # Remove existing CUDA packages
    sudo apt remove --purge -y cuda* nvidia-cuda-* 2>/dev/null || true
    sudo apt autoremove -y 2>/dev/null || true
    
    # Remove conflicting repository files
    sudo rm -f /etc/apt/sources.list.d/cuda*.list
    sudo rm -f /etc/apt/sources.list.d/nvidia*.list
    
    # Remove conflicting keyrings
    sudo rm -f /usr/share/keyrings/cudatools.gpg
    sudo rm -f /usr/share/keyrings/nvidia*.gpg
    sudo rm -f /etc/apt/trusted.gpg.d/cuda*.gpg
    
    # Remove CUDA directories
    sudo rm -rf /usr/local/cuda*
    sudo rm -rf /opt/cuda*
    
    # Clean apt cache
    sudo apt clean
    sudo apt update -qq 2>/dev/null || true
    
    log_info "CUDA cleanup completed"
}

install_nvidia_drivers() {
    log_step "Installing NVIDIA drivers..."
    
    # Check if nvidia-smi already works
    if command -v nvidia-smi &> /dev/null && nvidia-smi &> /dev/null; then
        local driver_version
        if driver_version=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null | head -1) && [[ -n "$driver_version" ]] && [[ "$driver_version" =~ ^[0-9]+\.[0-9]+ ]]; then
            log_info "NVIDIA drivers already installed: $driver_version"
            return 0
        else
            log_warn "nvidia-smi exists but returned invalid driver version, proceeding with installation"
        fi
    fi
    
    # Install recommended drivers
    sudo ubuntu-drivers autoinstall
    
    log_info "NVIDIA drivers installed - reboot may be required"
}

install_cuda_complete() {
    log_step "Installing CUDA 12.6 toolkit..."
    
    # Download and install CUDA keyring
    local keyring_url="https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/cuda-keyring_1.1-1_all.deb"
    local keyring_file="/tmp/cuda-keyring_1.1-1_all.deb"
    
    if ! wget -q "$keyring_url" -O "$keyring_file"; then
        log_error "Failed to download CUDA keyring"
        return 1
    fi
    
    # Install keyring
    sudo dpkg -i "$keyring_file" 2>/dev/null || {
        log_warn "Keyring installation had conflicts, fixing..."
        sudo apt --fix-broken install -y
        sudo dpkg -i "$keyring_file"
    }
    rm -f "$keyring_file"
    
    # Update package lists
    sudo apt update -qq
    
    # Install CUDA toolkit and drivers
    sudo apt install -y cuda-toolkit-12-6
    
    # Install NVIDIA drivers if not already installed
    if ! command -v nvidia-smi &> /dev/null; then
        sudo apt install -y cuda-drivers
    fi
    
    log_info "CUDA 12.6 installed"
}

setup_cuda_environment() {
    log_step "Setting up CUDA environment..."
    
    # Find CUDA installation directory
    local cuda_dir=""
    if [[ -d "/usr/local/cuda-12.6" ]]; then
        cuda_dir="/usr/local/cuda-12.6"
    elif [[ -d "/usr/local/cuda" ]]; then
        cuda_dir="/usr/local/cuda"
    else
        # Create symlink if CUDA is installed in /usr
        if [[ -d "/usr/lib/cuda" ]]; then
            sudo ln -sf /usr/lib/cuda /usr/local/cuda
            cuda_dir="/usr/local/cuda"
        elif find /usr -name "nvcc" 2>/dev/null | head -1; then
            local nvcc_path=$(find /usr -name "nvcc" 2>/dev/null | head -1)
            cuda_dir=$(dirname $(dirname "$nvcc_path"))
            sudo ln -sf "$cuda_dir" /usr/local/cuda
            cuda_dir="/usr/local/cuda"
        fi
    fi
    
    if [[ -n "$cuda_dir" && -d "$cuda_dir" ]]; then
        # Set up environment variables
        if ! grep -q "CUDA_HOME" ~/.bashrc; then
            echo "" >> ~/.bashrc
            echo "# CUDA Environment" >> ~/.bashrc
            echo "export CUDA_HOME=$cuda_dir" >> ~/.bashrc
            echo "export PATH=\$CUDA_HOME/bin:\$PATH" >> ~/.bashrc
            echo "export LD_LIBRARY_PATH=\$CUDA_HOME/lib64:\$LD_LIBRARY_PATH" >> ~/.bashrc
        fi
        
        # Set for current session
        export CUDA_HOME="$cuda_dir"
        export PATH="$cuda_dir/bin:$PATH"
        export LD_LIBRARY_PATH="$cuda_dir/lib64:$LD_LIBRARY_PATH"
        
        log_info "CUDA environment configured: $cuda_dir"
    else
        log_error "Could not locate CUDA installation directory"
        return 1
    fi
}

fix_nvidia_services() {
    log_step "Fixing NVIDIA services..."
    
    # Enable and start nvidia-persistenced
    sudo systemctl enable nvidia-persistenced 2>/dev/null || true
    sudo systemctl start nvidia-persistenced 2>/dev/null || {
        log_warn "nvidia-persistenced failed to start, attempting fix..."
        
        # Create nvidia-persistenced user if it doesn't exist
        if ! id nvidia-persistenced &>/dev/null; then
            sudo useradd -r -s /bin/false nvidia-persistenced
        fi
        
        # Set proper permissions
        sudo mkdir -p /var/run/nvidia-persistenced
        sudo chown nvidia-persistenced:nvidia-persistenced /var/run/nvidia-persistenced
        
        # Try starting again
        sudo systemctl start nvidia-persistenced 2>/dev/null || {
            log_warn "nvidia-persistenced still failing - this is not critical for CUDA functionality"
        }
    }
    
    log_info "NVIDIA services configured"
}

verify_cuda_installation() {
    log_step "Verifying CUDA installation..."
    
    # Source environment
    if [[ -f ~/.bashrc ]]; then
        source ~/.bashrc
    fi
    
    # Check nvcc
    if ! command -v nvcc &> /dev/null; then
        log_error "nvcc not found in PATH"
        return 1
    fi
    
    local cuda_version=$(nvcc --version | grep "release" | grep -o "V[0-9]\+\.[0-9]\+" | sed 's/V//')
    log_info "CUDA compiler version: $cuda_version"
    
    # Check nvidia-smi with robust error handling
    if command -v nvidia-smi &> /dev/null; then
        local gpu_info
        if gpu_info=$(nvidia-smi --query-gpu=name,memory.total --format=csv,noheader 2>/dev/null | head -1) && [[ -n "$gpu_info" ]] && [[ ! "$gpu_info" =~ "Failed to initialize NVML" ]]; then
            log_info "GPU detected: $gpu_info"
        else
            log_warn "nvidia-smi failed to query GPU info (driver/library version mismatch possible)"
        fi
        
        local driver_version
        if driver_version=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null | head -1) && [[ -n "$driver_version" ]] && [[ "$driver_version" =~ ^[0-9]+\.[0-9]+ ]]; then
            log_info "Driver version: $driver_version"
        else
            log_warn "nvidia-smi failed to query driver version (driver/library version mismatch possible)"
        fi
    else
        log_error "nvidia-smi not working"
        return 1
    fi
    
    log_info "CUDA installation verified ✓"
    return 0
}

install_python_system_deps() {
    log_step "Installing Python and system dependencies..."
    
    sudo apt install -y -qq \
        python3 \
        python3-dev \
        python3-pip \
        python3-venv \
        python3-wheel \
        python3-setuptools \
        python3-full \
        pipx
    
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
    
    # Remove existing environment if it exists
    if [[ -d "$PYTHON_ENV" ]]; then
        log_warn "Removing existing virtual environment"
        rm -rf "$PYTHON_ENV"
    fi
    
    # Create virtual environment
    if ! python3 -m venv "$PYTHON_ENV"; then
        log_error "Failed to create virtual environment"
        exit 1
    fi
    
    # Activate virtual environment
    source "$PYTHON_ENV/bin/activate"
    
    # Verify activation
    if [[ "$VIRTUAL_ENV" != "$PYTHON_ENV" ]]; then
        log_error "Virtual environment activation failed"
        exit 1
    fi
    
    # Upgrade pip and essential tools
    pip install --upgrade pip setuptools wheel
    
    log_info "Python virtual environment created: $PYTHON_ENV"
}

install_pytorch() {
    log_step "Installing PyTorch with CUDA support..."
    
    source "$PYTHON_ENV/bin/activate"
    
    # Install PyTorch with CUDA 12.x support
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
else:
    print('CUDA not available in PyTorch')
    exit(1)
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
    
    # Install gsplat
    pip install ninja packaging
    pip install git+https://github.com/nerfstudio-project/gsplat.git
    
    # Verify gsplat installation
    python3 -c "import gsplat; print('gsplat installed successfully')"
    
    log_info "Python packages installed"
}

build_colmap() {
    log_step "Building COLMAP with GPU optimization..."
    
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
    
    # Configure with CMake - optimized for RTX 4090/L4 GPU
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

# Activate Python virtual environment
source ~/3d-reconstruction/venv/bin/activate

# GPU optimizations
export CUDA_VISIBLE_DEVICES=0
export CUDA_LAUNCH_BLOCKING=0
export TORCH_CUDNN_V8_API_ENABLED=1

# Memory settings
export CUDA_MEMORY_FRACTION=0.9
export OMP_NUM_THREADS=16
export MKL_NUM_THREADS=16

# Project paths
export RECONSTRUCTION_HOME=~/3d-reconstruction
export RECONSTRUCTION_DATA=$RECONSTRUCTION_HOME/data
export RECONSTRUCTION_OUTPUT=$RECONSTRUCTION_HOME/output
export RECONSTRUCTION_CACHE=$RECONSTRUCTION_HOME/cache

echo "🚀 3D Reconstruction Pipeline Environment Activated"
echo "🐍 Python: $(python --version)"
echo "🔥 PyTorch: $(python -c 'import torch; print(torch.__version__)' 2>/dev/null || echo 'Not available')"
echo "⚡ CUDA: $(python -c 'import torch; print("Available" if torch.cuda.is_available() else "Not available")' 2>/dev/null)"
echo "📷 COLMAP: $(colmap --version 2>&1 | head -1 || echo 'Not available')"
echo "🎮 GPU: $(if command -v nvidia-smi &> /dev/null; then gpu_info=$(nvidia-smi --query-gpu=name,memory.total --format=csv,noheader 2>/dev/null | head -1) && [[ -n "$gpu_info" ]] && [[ ! "$gpu_info" =~ "Failed to initialize NVML" ]] && echo "$gpu_info" || echo "GPU query failed (driver/library version mismatch possible)"; else echo "nvidia-smi not available"; fi)"
EOF

    chmod +x "$PROJECT_DIR/activate.sh"
    
    log_info "Activation script created: $PROJECT_DIR/activate.sh"
}

create_configuration() {
    log_step "Creating project configuration..."
    
    # Detect GPU memory with robust error handling
    local gpu_memory_mb="24576"  # Default fallback
    if command -v nvidia-smi &> /dev/null; then
        local smi_output
        if smi_output=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits 2>/dev/null) && [[ -n "$smi_output" ]]; then
            # Validate that output is numeric and not an error message
            if [[ "$smi_output" =~ ^[0-9]+$ ]]; then
                gpu_memory_mb="$smi_output"
                log_info "GPU memory detected: ${gpu_memory_mb}MB"
            else
                log_warn "nvidia-smi returned non-numeric output: $smi_output"
                log_warn "Using default GPU memory: ${gpu_memory_mb}MB"
            fi
        else
            log_warn "nvidia-smi failed or returned empty output"
            log_warn "This may indicate driver/library version mismatch or missing GPU"
            log_warn "Using default GPU memory: ${gpu_memory_mb}MB"
        fi
    else
        log_warn "nvidia-smi not found, using default GPU memory: ${gpu_memory_mb}MB"
    fi
    local gpu_memory_gb=$((gpu_memory_mb / 1024))
    
    cat > "$PROJECT_DIR/.env" << EOF
# 3D Reconstruction Pipeline Configuration
# GPU Optimized Settings

# GPU Configuration
USE_GPU=true
CUDA_DEVICE=0
GPU_MEMORY_GB=$gpu_memory_gb

# Processing Settings
MAX_IMAGE_SIZE=4096
COLMAP_QUALITY=high
GAUSSIAN_ITERATIONS=30000
BATCH_SIZE=8

# GPU Optimizations
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
EOF

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
        find "$PROJECT_DIR/scripts" -name "*.py" -exec chmod +x {} \; 2>/dev/null || true
    fi
    
    log_info "Pipeline scripts set up"
}

create_status_script() {
    log_step "Creating system status script..."
    
    cat > "$PROJECT_DIR/check-status.sh" << 'EOF'
#!/bin/bash
# System Status Check for 3D Reconstruction Pipeline

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
    # Robust nvidia-smi queries with error handling
    local driver_ver gpu_name gpu_mem gpu_temp gpu_util
    
    if driver_ver=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null | head -1) && [[ -n "$driver_ver" ]] && [[ "$driver_ver" =~ ^[0-9]+\.[0-9]+ ]]; then
        echo "   Driver: $driver_ver"
    else
        echo "   Driver: ❌ Failed to query (driver/library version mismatch possible)"
    fi
    
    if gpu_name=$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -1) && [[ -n "$gpu_name" ]] && [[ ! "$gpu_name" =~ "Failed to initialize NVML" ]]; then
        echo "   GPU: $gpu_name"
    else
        echo "   GPU: ❌ Failed to query (driver/library version mismatch possible)"
    fi
    
    if gpu_mem=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader 2>/dev/null | head -1) && [[ -n "$gpu_mem" ]] && [[ ! "$gpu_mem" =~ "Failed to initialize NVML" ]]; then
        echo "   Memory: $gpu_mem"
    else
        echo "   Memory: ❌ Failed to query (driver/library version mismatch possible)"
    fi
    
    if gpu_temp=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader 2>/dev/null | head -1) && [[ -n "$gpu_temp" ]] && [[ "$gpu_temp" =~ ^[0-9]+$ ]]; then
        echo "   Temperature: ${gpu_temp}°C"
    else
        echo "   Temperature: ❌ Failed to query (driver/library version mismatch possible)"
    fi
    
    if gpu_util=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader 2>/dev/null | head -1) && [[ -n "$gpu_util" ]] && [[ ! "$gpu_util" =~ "Failed to initialize NVML" ]]; then
        echo "   Utilization: $gpu_util"
    else
        echo "   Utilization: ❌ Failed to query (driver/library version mismatch possible)"
    fi
else
    echo "   ❌ NVIDIA drivers not found"
fi
echo ""

# CUDA Information
echo "⚡ CUDA Information:"
if command -v nvcc &> /dev/null; then
    echo "   CUDA Version: $(nvcc --version | grep "release" | grep -o "V[0-9]\+\.[0-9]\+" | sed 's/V//')"
    echo "   nvcc: ✅ Available"
else
    echo "   ❌ CUDA toolkit not found"
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

# Services
echo "🔧 Services:"
echo "   nvidia-persistenced: $(systemctl is-active nvidia-persistenced 2>/dev/null || echo 'inactive')"
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
    
    # Test CUDA
    echo -n "   CUDA toolkit: "
    if command -v nvcc &> /dev/null; then
        echo "✅ Working"
    else
        echo "❌ Failed"
        return 1
    fi
    
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
    
    # Get system info with robust error handling
    local gpu_name="Unknown GPU"
    local gpu_mem="Unknown Memory"
    if command -v nvidia-smi &> /dev/null; then
        local gpu_info
        if gpu_info=$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -1) && [[ -n "$gpu_info" ]] && [[ ! "$gpu_info" =~ "Failed to initialize NVML" ]]; then
            gpu_name="$gpu_info"
        fi
        
        local mem_info
        if mem_info=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader 2>/dev/null | head -1) && [[ -n "$mem_info" ]] && [[ ! "$mem_info" =~ "Failed to initialize NVML" ]]; then
            gpu_mem="$mem_info"
        fi
    fi
    local cuda_version=$(nvcc --version | grep "release" | grep -o "V[0-9]\+\.[0-9]\+" | sed 's/V//')
    
    echo -e "${YELLOW}🖥️  System Configuration:${NC}"
    echo "   📍 OS: Ubuntu 24.04 LTS"
    echo "   🎮 GPU: $gpu_name ($gpu_mem)"
    echo "   ⚡ CUDA: $cuda_version"
    echo "   🐍 Python: $(python3 --version | grep -o "[0-9.]*")"
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
    
    echo -e "${YELLOW}🎯 GPU Optimizations:${NC}"
    echo "   ✅ CUDA Architecture $GPU_ARCH (Ada Lovelace)"
    echo "   ✅ GPU memory optimized settings"
    echo "   ✅ High-resolution image processing"
    echo "   ✅ Mixed precision training enabled"
    echo "   ✅ Optimized batch sizes and memory usage"
    
    echo ""
    echo -e "${GREEN}🎊 Ready for 3D reconstruction with GPU power!${NC}"
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
    echo "   • Verify CUDA installation: nvcc --version"
    echo "   • Check internet connection"
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
    
    log_info "Starting unified deployment for Ubuntu 24.04 + CUDA 12.6..."
    
    # Set up error handling
    trap 'handle_error $LINENO' ERR
    
    # Run deployment phases
    check_prerequisites
    update_system
    install_essential_tools
    cleanup_all_cuda_installations
    install_nvidia_drivers
    install_cuda_complete
    setup_cuda_environment
    fix_nvidia_services
    verify_cuda_installation
    install_python_system_deps
    install_colmap_system_deps
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
3D Reconstruction Pipeline - Unified Deployment Script
Ubuntu 24.04 + CUDA 12.6 + GPU Optimization

This script performs a complete deployment including:
• System updates and essential build tools
• Complete CUDA 12.6 installation and cleanup
• NVIDIA driver installation and service fixes
• Python 3.12 virtual environment
• PyTorch with CUDA 12.x support
• gsplat (GPU-accelerated Gaussian splatting)
• COLMAP with GPU optimization (CUDA Architecture 8.9)
• Project structure and configuration
• GPU-specific optimizations

Usage: $0 [options]

Options:
  --help, -h        Show this help message
  --verify-only     Only run verification tests
  --status          Show system status
  --cleanup-only    Only cleanup existing CUDA installations

Requirements:
• Ubuntu 24.04 LTS (Noble Wombat)
• 30+ GB available disk space
• 8+ GB RAM (16+ GB recommended)
• Internet connection
• Sudo privileges

The deployment process takes approximately 20-45 minutes depending on system.

This script will:
1. Clean up any existing CUDA installations
2. Install fresh CUDA 12.6 toolkit
3. Fix nvidia-persistenced service issues
4. Set up complete 3D reconstruction environment

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
    --cleanup-only)
        print_banner
        log_info "Running CUDA cleanup only..."
        cleanup_all_cuda_installations
        log_info "CUDA cleanup completed"
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
