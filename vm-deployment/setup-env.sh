#!/bin/bash
"""
Environment Configuration Script for 3D Reconstruction Pipeline
Sets up .env file and project configuration
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

PROJECT_HOME="$HOME/3d-reconstruction"
ENV_FILE="$PROJECT_HOME/.env"
ENV_TEMPLATE="$PROJECT_HOME/.env.template"

print_banner() {
    echo -e "${BLUE}================================================${NC}"
    echo -e "${BLUE}  Environment Configuration Setup              ${NC}"
    echo -e "${BLUE}  Bunny CDN + Pipeline Settings                ${NC}"
    echo -e "${BLUE}================================================${NC}"
}

check_prerequisites() {
    log_step "Checking prerequisites..."
    
    if [[ ! -d "$PROJECT_HOME" ]]; then
        log_error "Project directory not found: $PROJECT_HOME"
        log_error "Run setup-system.sh first"
        exit 1
    fi
    
    if [[ ! -f "$PROJECT_HOME/activate.sh" ]]; then
        log_error "Python environment not set up"
        log_error "Run build-deps.sh first"
        exit 1
    fi
    
    log_info "Prerequisites check passed ✓"
}

create_env_template() {
    log_step "Creating environment template..."
    
    cat > "$ENV_TEMPLATE" << 'EOF'
# =============================================================================
# 3D Reconstruction Pipeline Configuration
# =============================================================================

# Bunny CDN Configuration (REQUIRED)
BUNNY_API_KEY=your-api-key-here
BUNNY_STORAGE_ZONE=your-storage-zone-name

# Bunny CDN Paths (OPTIONAL - will use defaults if not set)
BUNNY_INPUT_PATH=images
BUNNY_OUTPUT_PATH=

# COLMAP Configuration (OPTIONAL)
COLMAP_FEATURE_TYPE=sift
COLMAP_MATCHER_TYPE=sequential
COLMAP_CAMERA_MODEL=OPENCV

# gsplat Gaussian Splatting Configuration (OPTIONAL)
GSPLAT_ITERATIONS=30000
GSPLAT_SAVE_INTERVAL=5000
GSPLAT_MCMC_CAP=1000000
GSPLAT_ENABLE_ABSGRAD=true
GSPLAT_ENABLE_ANTIALIASING=true
GSPLAT_ENABLE_MCMC=false
GSPLAT_ENABLE_DISTRIBUTED=true

# Performance Configuration (OPTIONAL)
MAX_DOWNLOAD_WORKERS=4
MAX_UPLOAD_WORKERS=2
ENABLE_AUTO_UPLOAD=true
ENABLE_DENSE_RECONSTRUCTION=false

# GPU Configuration (OPTIONAL)
CUDA_VISIBLE_DEVICES=0
OMP_NUM_THREADS=16
MKL_NUM_THREADS=16

# Advanced Settings (OPTIONAL)
DEBUG_MODE=false
SAVE_INTERMEDIATE_RESULTS=true
COMPRESSION_ENABLED=true
EOF
    
    log_info "Environment template created: $ENV_TEMPLATE"
}

create_initial_env() {
    log_step "Creating initial environment file..."
    
    if [[ -f "$ENV_FILE" ]]; then
        log_warn "Environment file already exists: $ENV_FILE"
        read -p "Overwrite existing file? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Keeping existing environment file"
            return 0
        fi
    fi
    
    cp "$ENV_TEMPLATE" "$ENV_FILE"
    log_info "Environment file created: $ENV_FILE"
}

interactive_configuration() {
    log_step "Interactive configuration setup..."
    
    echo ""
    echo -e "${YELLOW}Configure Bunny CDN (required for pipeline):${NC}"
    echo ""
    
    # Bunny CDN API Key
    read -p "Enter Bunny CDN API Key: " bunny_api_key
    if [[ -n "$bunny_api_key" ]]; then
        sed -i "s/your-api-key-here/$bunny_api_key/" "$ENV_FILE"
    fi
    
    # Bunny CDN Storage Zone
    read -p "Enter Bunny CDN Storage Zone: " bunny_zone
    if [[ -n "$bunny_zone" ]]; then
        sed -i "s/your-storage-zone-name/$bunny_zone/" "$ENV_FILE"
    fi
    
    # Input path
    echo ""
    read -p "Input images path on CDN (default: images): " input_path
    if [[ -n "$input_path" ]]; then
        sed -i "s/BUNNY_INPUT_PATH=images/BUNNY_INPUT_PATH=$input_path/" "$ENV_FILE"
    fi
    
    # Quality settings
    echo ""
    echo -e "${YELLOW}Quality Settings:${NC}"
    read -p "Training iterations (default: 30000, high quality: 100000): " iterations
    if [[ -n "$iterations" ]]; then
        sed -i "s/GSPLAT_ITERATIONS=30000/GSPLAT_ITERATIONS=$iterations/" "$ENV_FILE"
    fi
    
    read -p "Enable dense reconstruction? (slower but higher quality) [y/N]: " -n 1 -r dense
    echo
    if [[ $dense =~ ^[Yy]$ ]]; then
        sed -i "s/ENABLE_DENSE_RECONSTRUCTION=false/ENABLE_DENSE_RECONSTRUCTION=true/" "$ENV_FILE"
    fi
    
    read -p "Enable MCMC strategy? (experimental, may improve quality) [y/N]: " -n 1 -r mcmc
    echo
    if [[ $mcmc =~ ^[Yy]$ ]]; then
        sed -i "s/GSPLAT_ENABLE_MCMC=false/GSPLAT_ENABLE_MCMC=true/" "$ENV_FILE"
        sed -i "s/GSPLAT_MCMC_CAP=1000000/GSPLAT_MCMC_CAP=3000000/" "$ENV_FILE"
    fi
    
    log_info "Interactive configuration completed"
}

validate_configuration() {
    log_step "Validating configuration..."
    
    source "$ENV_FILE"
    
    # Check required settings
    if [[ -z "$BUNNY_API_KEY" || "$BUNNY_API_KEY" == "your-api-key-here" ]]; then
        log_warn "Bunny CDN API key not configured"
        log_warn "Pipeline will only work with local images"
    else
        log_info "Bunny CDN API key configured ✓"
    fi
    
    if [[ -z "$BUNNY_STORAGE_ZONE" || "$BUNNY_STORAGE_ZONE" == "your-storage-zone-name" ]]; then
        log_warn "Bunny CDN storage zone not configured"
        log_warn "Pipeline will only work with local images"
    else
        log_info "Bunny CDN storage zone configured ✓"
    fi
    
    # Validate numeric settings
    if ! [[ "$GSPLAT_ITERATIONS" =~ ^[0-9]+$ ]]; then
        log_error "Invalid GSPLAT_ITERATIONS value: $GSPLAT_ITERATIONS"
        exit 1
    fi
    
    if ! [[ "$MAX_DOWNLOAD_WORKERS" =~ ^[0-9]+$ ]]; then
        log_error "Invalid MAX_DOWNLOAD_WORKERS value: $MAX_DOWNLOAD_WORKERS"
        exit 1
    fi
    
    log_info "Configuration validation passed ✓"
}

create_project_structure() {
    log_step "Creating project directory structure..."
    
    # Create all necessary directories
    mkdir -p "$PROJECT_HOME"/{data,output,cache,logs,scripts,config}
    mkdir -p "$PROJECT_HOME/data"/{images,models}
    mkdir -p "$PROJECT_HOME/output"/{colmap,gaussian,results}
    mkdir -p "$PROJECT_HOME/cache"/{colmap,downloads,temp}
    
    log_info "Project structure created"
}

create_helper_scripts() {
    log_step "Creating helper scripts..."
    
    # Create quick start script
    cat > "$PROJECT_HOME/quick-start.sh" << 'EOF'
#!/bin/bash
# Quick Start Guide for 3D Reconstruction Pipeline

echo "3D Reconstruction Pipeline - Quick Start"
echo "======================================="
echo ""
echo "1. Activate Environment:"
echo "   source ~/3d-reconstruction/activate.sh"
echo ""
echo "2. Test Installation:"
echo "   python3 -c 'import torch, gsplat; print(\"Ready!\")'"
echo "   colmap --help | head -5"
echo ""
echo "3. Place Images (if not using CDN):"
echo "   cp /path/to/your/images/* ~/3d-reconstruction/data/images/"
echo ""
echo "4. Run Reconstruction:"
echo "   ./run-reconstruction.sh"
echo ""
echo "5. View Results:"
echo "   ls -la ~/3d-reconstruction/output/"
echo ""

# Source environment
source ~/3d-reconstruction/activate.sh

echo "Environment activated. Ready to run reconstruction pipeline!"
EOF
    
    chmod +x "$PROJECT_HOME/quick-start.sh"
    
    # Create status check script
    cat > "$PROJECT_HOME/check-status.sh" << 'EOF'
#!/bin/bash
# Check system and environment status

source ~/3d-reconstruction/activate.sh 2>/dev/null || echo "Warning: Could not activate environment"

echo "3D Reconstruction Pipeline - System Status"
echo "=========================================="
echo ""
echo "System Information:"
echo "  OS: $(lsb_release -d 2>/dev/null | cut -f2 || uname -a)"
echo "  CPU: $(nproc) cores"
echo "  RAM: $(free -h | awk 'NR==2{printf "%s", $2}')"
echo "  Disk: $(df -h ~ | awk 'NR==2{printf "%s available", $4}')"
echo ""
echo "GPU Information:"
if command -v nvidia-smi &> /dev/null; then
    echo "  $(nvidia-smi --query-gpu=name,memory.total --format=csv,noheader,nounits)"
else
    echo "  No GPU detected"
fi
echo ""
echo "Software Status:"
echo "  CUDA: $(nvcc --version 2>/dev/null | grep "release" | grep -o "V[0-9.]*" | sed 's/V//' || echo 'Not installed')"
echo "  Python: $(python3 --version 2>/dev/null | grep -o "[0-9.]*" || echo 'Not available')"
echo "  PyTorch: $(python3 -c 'import torch; print(torch.__version__)' 2>/dev/null || echo 'Not installed')"
echo "  gsplat: $(python3 -c 'import gsplat; print("Installed")' 2>/dev/null || echo 'Not installed')"
echo "  COLMAP: $(colmap --version 2>&1 | head -1 || echo 'Not installed')"
echo ""
echo "Environment Status:"
if [[ -f ~/3d-reconstruction/.env ]]; then
    echo "  Configuration: ✓ Found"
    source ~/3d-reconstruction/.env
    if [[ "$BUNNY_API_KEY" != "your-api-key-here" ]]; then
        echo "  Bunny CDN: ✓ Configured"
    else
        echo "  Bunny CDN: ⚠ Not configured"
    fi
else
    echo "  Configuration: ✗ Missing"
fi
echo ""
EOF
    
    chmod +x "$PROJECT_HOME/check-status.sh"
    
    log_info "Helper scripts created"
}

display_summary() {
    echo ""
    echo -e "${GREEN}Environment Setup Complete!${NC}"
    echo ""
    echo -e "${YELLOW}Configuration Files:${NC}"
    echo "  Environment: $ENV_FILE"
    echo "  Template: $ENV_TEMPLATE"
    echo ""
    echo -e "${YELLOW}Helper Scripts:${NC}"
    echo "  Quick Start: $PROJECT_HOME/quick-start.sh"
    echo "  Status Check: $PROJECT_HOME/check-status.sh"
    echo "  Activation: $PROJECT_HOME/activate.sh"
    echo ""
    echo -e "${YELLOW}Next Steps:${NC}"
    echo "  1. Edit configuration if needed: nano $ENV_FILE"
    echo "  2. Test setup: ./check-status.sh"
    echo "  3. Run pipeline: ./run-reconstruction.sh"
    echo ""
    if [[ "$BUNNY_API_KEY" == "your-api-key-here" ]]; then
        echo -e "${YELLOW}Note:${NC} Bunny CDN not configured. Pipeline will only work with local images."
        echo "      Place images in: $PROJECT_HOME/data/images/"
    fi
}

main() {
    print_banner
    
    check_prerequisites
    create_env_template
    create_initial_env
    
    # Ask if user wants interactive configuration
    read -p "Run interactive configuration? [Y/n]: " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        interactive_configuration
    fi
    
    validate_configuration
    create_project_structure
    create_helper_scripts
    display_summary
}

case "${1:-}" in
    --help|-h)
        echo "Environment Configuration for 3D Reconstruction Pipeline"
        echo "Usage: $0 [--template-only]"
        echo ""
        echo "Creates:"
        echo "  - .env configuration file"
        echo "  - Project directory structure"
        echo "  - Helper scripts"
        echo ""
        echo "Options:"
        echo "  --template-only    Create template only, skip interactive config"
        exit 0
        ;;
    --template-only)
        check_prerequisites
        create_env_template
        create_project_structure
        echo "Template created: $ENV_TEMPLATE"
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
