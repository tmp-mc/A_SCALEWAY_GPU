#!/bin/bash
#
# 3D Reconstruction Pipeline - Main Script
# Simple workflow: Download → COLMAP → gsplat → Upload
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step() { echo -e "${BLUE}[STEP]${NC} $1"; }
log_s3() { echo -e "${CYAN}[S3]${NC} $1"; }

# Configuration
PROJECT_HOME="$HOME/3d-reconstruction"
SCRIPTS_DIR="$PROJECT_HOME/scripts"
DATA_DIR="$PROJECT_HOME/data"
OUTPUT_DIR="$PROJECT_HOME/output"
CACHE_DIR="$PROJECT_HOME/cache"
ENV_FILE="$PROJECT_HOME/.env"

print_banner() {
    echo -e "${CYAN}================================================${NC}"
    echo -e "${CYAN}  3D Reconstruction Pipeline                    ${NC}"
    echo -e "${CYAN}  COLMAP + gsplat + Hetzner S3                  ${NC}"
    echo -e "${CYAN}================================================${NC}"
}

check_prerequisites() {
    log_step "Checking prerequisites..."
    
    # Check if environment is activated
    if [[ -z "$RECONSTRUCTION_HOME" ]]; then
        log_error "Environment not activated. Run: source ~/3d-reconstruction/activate.sh"
        exit 1
    fi
    
    # Check configuration
    if [[ ! -f "$ENV_FILE" ]]; then
        log_error "Configuration not found. Run: ./setup-env.sh"
        exit 1
    fi
    
    # Load configuration
    source "$ENV_FILE"
    
    # Check required tools
    if ! command -v colmap &> /dev/null; then
        log_error "COLMAP not found. Run: ./build-deps.sh"
        exit 1
    fi
    
    if ! python3 -c "import torch, gsplat" &> /dev/null; then
        log_error "PyTorch or gsplat not available. Run: ./build-deps.sh"
        exit 1
    fi
    
    log_info "Prerequisites check passed ✓"
}

check_gpu() {
    log_step "Checking GPU availability..."
    
    if command -v nvidia-smi &> /dev/null; then
        gpu_count=$(nvidia-smi --query-gpu=count --format=csv,noheader,nounits 2>/dev/null || echo "0")
        if [[ "$gpu_count" -gt 0 ]]; then
            gpu_names=$(nvidia-smi --query-gpu=name --format=csv,noheader | tr '\n' ', ' | sed 's/, $//')
            log_info "GPUs detected ($gpu_count): $gpu_names"
            
            # Check memory
            gpu_mem=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits | head -1)
            if [[ "$gpu_mem" -lt 8000 ]]; then
                log_warn "Low GPU memory: ${gpu_mem}MB (recommended: 8GB+)"
            fi
        else
            log_warn "No GPU detected - reconstruction will be slower"
        fi
    else
        log_warn "nvidia-smi not available"
    fi
}

prepare_workspace() {
    log_step "Preparing workspace..."
    
    # Create directories
    mkdir -p "$DATA_DIR/images" "$OUTPUT_DIR"/{colmap,gaussian,results} "$CACHE_DIR"
    
    # Clean previous runs if requested
    if [[ "${CLEAN_PREVIOUS:-false}" == "true" ]]; then
        log_info "Cleaning previous results..."
        rm -rf "$OUTPUT_DIR"/{colmap,gaussian}/*
        rm -rf "$CACHE_DIR"/*
    fi
    
    log_info "Workspace ready"
}

download_images() {
    local use_s3="${1:-auto}"
    
    # Auto-detect S3 usage
    if [[ "$use_s3" == "auto" ]]; then
        if [[ -n "$HETZNER_BUCKET_NAME" && "$HETZNER_BUCKET_NAME" != "your-bucket-name" ]]; then
            use_s3="true"
        else
            use_s3="false"
        fi
    fi
    
    if [[ "$use_s3" == "true" ]]; then
        log_step "Downloading images from Hetzner S3..."
        log_s3 "Bucket: $HETZNER_BUCKET_NAME"
        log_s3 "Input Path: ${HETZNER_INPUT_PATH:-inputs}"
        
        # Check if credentials are available in environment
        if [[ -z "$HETZNER_ACCESS_KEY" || "$HETZNER_ACCESS_KEY" == "your-access-key-here" ]]; then
            log_info "Hetzner S3 credentials required for download"
            log_info "Set HETZNER_ACCESS_KEY and HETZNER_SECRET_KEY environment variables or script will prompt for them"
        fi
        
        python3 "$SCRIPTS_DIR/hetzner_s3.py" download \
            --bucket-name "$HETZNER_BUCKET_NAME" \
            --remote-path "${HETZNER_INPUT_PATH:-inputs}" \
            --local-path "$DATA_DIR/images" \
            --max-workers "${MAX_DOWNLOAD_WORKERS:-4}" \
            --extensions .jpg .jpeg .png .tiff .bmp
        
        if [[ $? -ne 0 ]]; then
            log_error "Failed to download images from S3"
            exit 1
        fi
    else
        log_step "Using local images..."
        log_info "Local images directory: $DATA_DIR/images"
    fi
    
    # Count images
    image_count=$(find "$DATA_DIR/images" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.tiff" -o -iname "*.bmp" \) | wc -l)
    
    if [[ "$image_count" -lt 3 ]]; then
        log_error "Insufficient images for reconstruction (found: $image_count, minimum: 3)"
        if [[ "$use_s3" == "false" ]]; then
            log_error "Place images in: $DATA_DIR/images/"
        fi
        exit 1
    fi
    
    log_info "Images ready: $image_count files"
}

download_vocabulary_tree() {
    log_step "Checking vocabulary tree..."
    
    local vocab_tree_path="$CACHE_DIR/vocab_tree_flickr100K_words1M.bin"
    local vocab_tree_url="https://demuc.de/colmap/vocab_tree_flickr100K_words1M.bin"
    
    if [[ -f "$vocab_tree_path" ]]; then
        local file_size=$(stat -c%s "$vocab_tree_path" 2>/dev/null || stat -f%z "$vocab_tree_path" 2>/dev/null || echo "0")
        if [[ "$file_size" -gt 100000000 ]]; then  # ~100MB minimum
            log_info "Vocabulary tree already available ✓"
            return 0
        else
            log_warn "Vocabulary tree file corrupted, re-downloading..."
            rm -f "$vocab_tree_path"
        fi
    fi
    
    log_info "Downloading vocabulary tree (large file, ~600MB)..."
    log_info "This may take several minutes depending on your internet connection..."
    
    if command -v wget &> /dev/null; then
        wget --progress=bar:force --timeout=300 -O "$vocab_tree_path" "$vocab_tree_url"
    elif command -v curl &> /dev/null; then
        curl --progress-bar --max-time 300 -L -o "$vocab_tree_path" "$vocab_tree_url"
    else
        log_error "Neither wget nor curl available for downloading vocabulary tree"
        log_error "Please install wget or curl, or manually download:"
        log_error "URL: $vocab_tree_url"
        log_error "Path: $vocab_tree_path"
        exit 1
    fi
    
    if [[ $? -ne 0 ]]; then
        log_error "Failed to download vocabulary tree"
        log_warn "Sequential matching will work without vocabulary tree, but with reduced loop detection"
        rm -f "$vocab_tree_path"  # Clean up partial download
        return 1
    fi
    
    # Verify download
    local downloaded_size=$(stat -c%s "$vocab_tree_path" 2>/dev/null || stat -f%z "$vocab_tree_path" 2>/dev/null || echo "0")
    if [[ "$downloaded_size" -lt 100000000 ]]; then
        log_error "Vocabulary tree download appears incomplete (size: ${downloaded_size} bytes)"
        rm -f "$vocab_tree_path"
        return 1
    fi
    
    log_info "Vocabulary tree downloaded successfully ✓ (${downloaded_size} bytes)"
    return 0
}

run_colmap_reconstruction() {
    log_step "Running COLMAP reconstruction..."
    
    local colmap_dir="$OUTPUT_DIR/colmap"
    local database="$CACHE_DIR/database.db"
    local sparse_dir="$colmap_dir/sparse"
    
    mkdir -p "$colmap_dir" "$sparse_dir"
    
    # Feature extraction
    log_info "Extracting features..."
    colmap feature_extractor \
        --database_path "$database" \
        --image_path "$DATA_DIR/images" \
        --ImageReader.camera_model "${COLMAP_CAMERA_MODEL:-RADIAL}" \
        --SiftExtraction.use_gpu true \
        --SiftExtraction.gpu_index 0
    
    if [[ $? -ne 0 ]]; then
        log_error "Feature extraction failed"
        exit 1
    fi
    
    # Feature matching
    log_info "Matching features..."
    if [[ "${COLMAP_MATCHER_TYPE:-sequential}" == "exhaustive" ]]; then
        colmap exhaustive_matcher \
            --database_path "$database" \
            --SiftMatching.use_gpu true \
            --SiftMatching.gpu_index 0
    elif [[ "${COLMAP_MATCHER_TYPE:-sequential}" == "sequential" ]]; then
        # Sequential matcher with vocabulary tree for loop detection
        log_info "Using sequential matcher with vocabulary tree..."
        colmap sequential_matcher \
            --database_path "$database" \
            --SiftMatching.use_gpu true \
            --SiftMatching.gpu_index 0 \
            --SequentialMatching.overlap 10 \
            --SequentialMatching.loop_detection 1 \
            --SequentialMatching.loop_detection_period 10 \
            --SequentialMatching.loop_detection_num_images 50 \
            --SequentialMatching.vocab_tree_path "$CACHE_DIR/vocab_tree_flickr100K_words1M.bin"
    else
        # Fallback to vocabulary tree matcher
        colmap vocab_tree_matcher \
            --database_path "$database" \
            --SiftMatching.use_gpu true \
            --SiftMatching.gpu_index 0 \
            --VocabTreeMatching.vocab_tree_path "$CACHE_DIR/vocab_tree_flickr100K_words1M.bin"
    fi
    
    if [[ $? -ne 0 ]]; then
        log_error "Feature matching failed"
        exit 1
    fi
    
    # Sparse reconstruction
    log_info "Building sparse reconstruction..."
    colmap mapper \
        --database_path "$database" \
        --image_path "$DATA_DIR/images" \
        --output_path "$sparse_dir"
    
    if [[ $? -ne 0 ]] || [[ ! -d "$sparse_dir/0" ]]; then
        log_error "Sparse reconstruction failed"
        exit 1
    fi
    
    log_info "COLMAP reconstruction completed ✓"
    
    # Optional dense reconstruction
    if [[ "${ENABLE_DENSE_RECONSTRUCTION:-false}" == "true" ]]; then
        log_info "Running dense reconstruction..."
        
        local dense_dir="$sparse_dir/0/dense"
        mkdir -p "$dense_dir"
        
        colmap image_undistorter \
            --image_path "$DATA_DIR/images" \
            --input_path "$sparse_dir/0" \
            --output_path "$dense_dir" \
            --output_type COLMAP
        
        colmap patch_match_stereo \
            --workspace_path "$dense_dir" \
            --workspace_format COLMAP
        
        colmap stereo_fusion \
            --workspace_path "$dense_dir" \
            --workspace_format COLMAP \
            --input_type geometric \
            --output_path "$dense_dir/fused.ply"
        
        log_info "Dense reconstruction completed ✓"
    fi
}

run_gaussian_splatting() {
    log_step "Running Gaussian Splatting training..."
    
    local sparse_model="$OUTPUT_DIR/colmap/sparse/0"
    local gaussian_output="$OUTPUT_DIR/gaussian"
    
    if [[ ! -d "$sparse_model" ]]; then
        log_error "COLMAP sparse model not found: $sparse_model"
        exit 1
    fi
    
    # Copy images to sparse model directory for gsplat
    if [[ ! -d "$sparse_model/images" ]]; then
        cp -r "$DATA_DIR/images" "$sparse_model/images"
    fi
    
    mkdir -p "$gaussian_output"
    
    # Run gsplat training
    python3 "$SCRIPTS_DIR/gsplat_trainer.py" \
        --colmap_path "$sparse_model" \
        --output_path "$gaussian_output" \
        --iterations "${GSPLAT_ITERATIONS:-30000}" \
        --mcmc_cap "${GSPLAT_MCMC_CAP:-1000000}" \
        $([ "${GSPLAT_ENABLE_ABSGRAD:-true}" != "true" ] && echo "--disable_absgrad") \
        $([ "${GSPLAT_ENABLE_ANTIALIASING:-true}" != "true" ] && echo "--disable_antialiasing") \
        $([ "${GSPLAT_ENABLE_MCMC:-false}" == "true" ] && echo "" || echo "--disable_mcmc") \
        $([ "${GSPLAT_ENABLE_DISTRIBUTED:-true}" != "true" ] && echo "--disable_distributed")
    
    if [[ $? -ne 0 ]]; then
        log_error "Gaussian splatting training failed"
        exit 1
    fi
    
    log_info "Gaussian splatting completed ✓"
}

organize_results() {
    log_step "Organizing results..."
    
    local results_dir="$OUTPUT_DIR/results"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local run_dir="$results_dir/run_$timestamp"
    
    mkdir -p "$run_dir"/{colmap,gaussian,logs}
    
    # Copy COLMAP results
    if [[ -d "$OUTPUT_DIR/colmap/sparse" ]]; then
        cp -r "$OUTPUT_DIR/colmap/sparse" "$run_dir/colmap/"
    fi
    
    # Copy Gaussian splatting results
    if [[ -d "$OUTPUT_DIR/gaussian" ]]; then
        cp -r "$OUTPUT_DIR/gaussian"/* "$run_dir/gaussian/" 2>/dev/null || true
    fi
    
    # Create summary
    cat > "$run_dir/summary.txt" << EOF
3D Reconstruction Pipeline Results
=================================
Date: $(date)
Input Images: $(find "$DATA_DIR/images" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) 2>/dev/null | wc -l)
COLMAP Sparse: $([ -f "$run_dir/colmap/sparse/0/cameras.bin" ] && echo "✓ Success" || echo "✗ Failed")
Dense Reconstruction: $([ "${ENABLE_DENSE_RECONSTRUCTION:-false}" == "true" ] && echo "Enabled" || echo "Disabled")
Gaussian Splatting: $([ -f "$run_dir/gaussian/final_model.pt" ] && echo "✓ Success" || echo "✗ Failed")
Training Iterations: ${GSPLAT_ITERATIONS:-30000}

Configuration:
- COLMAP Camera Model: ${COLMAP_CAMERA_MODEL:-OPENCV}
- COLMAP Matcher: ${COLMAP_MATCHER_TYPE:-sequential}
- gsplat AbsGrad: ${GSPLAT_ENABLE_ABSGRAD:-true}
- gsplat Antialiasing: ${GSPLAT_ENABLE_ANTIALIASING:-true}
- gsplat MCMC: ${GSPLAT_ENABLE_MCMC:-false}

Files Generated:
$(find "$run_dir" -type f -exec ls -lh {} \; 2>/dev/null | head -20)
EOF
    
    # Create latest symlink
    ln -sfn "$run_dir" "$results_dir/latest"
    
    log_info "Results organized in: $run_dir"
    echo "$run_dir"
}

upload_results() {
    local results_dir="$1"
    
    if [[ "${ENABLE_AUTO_UPLOAD:-true}" != "true" ]]; then
        log_info "Auto-upload disabled, skipping upload"
        return 0
    fi
    
    if [[ -z "$HETZNER_BUCKET_NAME" || "$HETZNER_BUCKET_NAME" == "your-bucket-name" ]]; then
        log_info "Hetzner S3 not configured, skipping upload"
        return 0
    fi
    
    log_step "Uploading results to Hetzner S3..."
    
    local remote_path="${HETZNER_OUTPUT_PATH:-output}/$(basename "$results_dir")"
    
    log_s3 "Bucket: $HETZNER_BUCKET_NAME"
    log_s3 "Remote Path: $remote_path"
    
    # Check if credentials are available in environment
    if [[ -z "$HETZNER_ACCESS_KEY" || "$HETZNER_ACCESS_KEY" == "your-access-key-here" ]]; then
        log_info "Hetzner S3 credentials required for upload"
        log_info "Set HETZNER_ACCESS_KEY and HETZNER_SECRET_KEY environment variables or script will prompt for them"
    fi
    
    python3 "$SCRIPTS_DIR/hetzner_s3.py" upload \
        --bucket-name "$HETZNER_BUCKET_NAME" \
        --local-path "$results_dir" \
        --remote-path "$remote_path" \
        --max-workers "${MAX_UPLOAD_WORKERS:-2}"
    
    if [[ $? -eq 0 ]]; then
        log_s3 "Results uploaded successfully ✓"
        log_s3 "URL: https://${HETZNER_BUCKET_NAME}.${HETZNER_S3_ENDPOINT#https://}/$remote_path/"
        return 0
    else
        log_warn "Upload failed, but reconstruction completed successfully"
        return 1
    fi
}

cleanup() {
    log_step "Cleaning up temporary files..."
    
    # Clean cache if requested
    if [[ "${CLEAN_CACHE:-false}" == "true" ]]; then
        rm -rf "$CACHE_DIR"/*
        log_info "Cache cleaned"
    fi
    
    # Clean intermediate outputs if requested
    if [[ "${SAVE_INTERMEDIATE_RESULTS:-true}" != "true" ]]; then
        rm -rf "$OUTPUT_DIR/colmap" "$OUTPUT_DIR/gaussian"
        log_info "Intermediate results cleaned"
    fi
}

display_summary() {
    local results_dir="$1"
    local upload_success="$2"
    
    echo ""
    echo -e "${GREEN}🎉 3D Reconstruction Pipeline Completed Successfully!${NC}"
    echo ""
    echo -e "${YELLOW}Results Summary:${NC}"
    cat "$results_dir/summary.txt"
    echo ""
    echo -e "${YELLOW}Generated Files:${NC}"
    echo "  📁 Results: $results_dir"
    echo "  📁 Latest: $OUTPUT_DIR/results/latest"
    
    if [[ -f "$results_dir/gaussian/final_model.pt" ]]; then
        echo "  🎯 Final Model: $results_dir/gaussian/final_model.pt"
    fi
    
    if [[ -f "$results_dir/gaussian/point_cloud.ply" ]]; then
        echo "  ☁️  Point Cloud: $results_dir/gaussian/point_cloud.ply"
    fi
    
    if [[ "$upload_success" == "0" ]]; then
        echo "  ☁️  S3: https://${HETZNER_BUCKET_NAME}.${HETZNER_S3_ENDPOINT#https://}/${HETZNER_OUTPUT_PATH:-output}/$(basename "$results_dir")/"
    fi
    
    echo ""
    echo -e "${YELLOW}Next Steps:${NC}"
    echo "  • View point cloud with Open3D or MeshLab"
    echo "  • Use gsplat viewer for interactive visualization"
    echo "  • Check summary.txt for detailed statistics"
}

main() {
    local start_time=$(date +%s)
    
    print_banner
    
    check_prerequisites
    check_gpu
    prepare_workspace
    
    # Pipeline execution
    download_images "${USE_CDN:-auto}"
    
    # Download vocabulary tree for sequential/vocab tree matching
    if [[ "${COLMAP_MATCHER_TYPE:-sequential}" == "sequential" ]] || [[ "${COLMAP_MATCHER_TYPE:-sequential}" == "vocab_tree" ]]; then
        download_vocabulary_tree || log_warn "Continuing without vocabulary tree - matching may be less robust"
    fi
    
    run_colmap_reconstruction
    run_gaussian_splatting
    
    # Results processing
    results_dir=$(organize_results)
    upload_success=1
    upload_results "$results_dir" && upload_success=0
    
    cleanup
    display_summary "$results_dir" "$upload_success"
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    local hours=$((duration / 3600))
    local minutes=$(((duration % 3600) / 60))
    local seconds=$((duration % 60))
    
    echo ""
    echo -e "${CYAN}Total time: ${hours}h ${minutes}m ${seconds}s${NC}"
    echo ""
}

# Command line interface
case "${1:-}" in
    --help|-h)
        cat << EOF
3D Reconstruction Pipeline - Main Script

Usage: $0 [options]

Options:
  --local-only      Use local images only (skip CDN download)
  --cdn-only        Force CDN download even if not configured
  --clean           Clean previous results before starting
  --no-upload       Skip uploading results to CDN
  --high-quality    Use high-quality settings (longer processing)
  --fast            Use fast settings (lower quality)

Examples:
  $0                # Auto-detect CDN, standard quality
  $0 --local-only   # Use local images in ~/3d-reconstruction/data/images/
  $0 --high-quality # Maximum quality settings (may take hours)
  $0 --fast         # Quick reconstruction for testing

Environment:
  Activate first: source ~/3d-reconstruction/activate.sh
  Configure: Edit ~/3d-reconstruction/.env

EOF
        exit 0
        ;;
    --local-only)
        export USE_CDN="false"
        main
        ;;
    --cdn-only)
        export USE_CDN="true"
        main
        ;;
    --clean)
        export CLEAN_PREVIOUS="true"
        main
        ;;
    --no-upload)
        export ENABLE_AUTO_UPLOAD="false"
        main
        ;;
    --high-quality)
        export GSPLAT_ITERATIONS=100000
        export GSPLAT_MCMC_CAP=3000000
        export GSPLAT_ENABLE_MCMC=true
        export ENABLE_DENSE_RECONSTRUCTION=true
        main
        ;;
    --fast)
        export GSPLAT_ITERATIONS=10000
        export GSPLAT_MCMC_CAP=500000
        export GSPLAT_ENABLE_MCMC=false
        export ENABLE_DENSE_RECONSTRUCTION=false
        main
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
