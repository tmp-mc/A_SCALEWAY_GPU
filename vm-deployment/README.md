# 3D Reconstruction Pipeline - VM Deployment

Simple, script-based deployment of a complete 3D reconstruction pipeline on Ubuntu 24.04 VMs. No Docker required - just clean, executable shell scripts.

## 🚀 Quick Start

```bash
# Clone the deployment scripts to your VM
git clone <repo-url> vm-deployment
cd vm-deployment

# One-command deployment (30-60 minutes)
chmod +x deploy.sh
./deploy.sh
```

That's it! The script will:
- Install CUDA 12.6 and GPU drivers
- Build COLMAP with CUDA support
- Set up Python environment with PyTorch and gsplat
- Configure Bunny CDN integration
- Create complete project structure

## 📋 Requirements

- **OS**: Ubuntu 24.04 LTS (fresh VM recommended)
- **Disk**: 30+ GB available space
- **RAM**: 8+ GB (16+ GB recommended)
- **GPU**: NVIDIA GPU recommended (RTX 4090 optimized)
- **Network**: Stable internet connection
- **Access**: sudo privileges

## 🛠️ Manual Deployment (Step by Step)

If you prefer to run each phase manually:

```bash
# Phase 1: System setup (CUDA, dependencies)
./setup-system.sh

# Reload environment variables
source ~/.bashrc

# Phase 2: Build dependencies (COLMAP, Python packages)
./build-deps.sh

# Phase 3: Configure environment
./setup-env.sh
```

## 📁 Project Structure

After deployment, you'll have a complete project in `~/3d-reconstruction/`:

```
~/3d-reconstruction/
├── activate.sh                 # Environment activation
├── .env                        # Configuration file
├── .env.template              # Configuration template
├── run-reconstruction.sh      # Main pipeline script
├── check-status.sh           # System status checker
├── quick-start.sh            # Quick start guide
├── scripts/
│   ├── bunny_cdn.py          # CDN integration
│   └── gsplat_trainer.py     # Gaussian splatting trainer
├── data/
│   └── images/               # Input images directory
├── output/
│   ├── colmap/              # COLMAP results
│   ├── gaussian/            # Gaussian splatting results
│   └── results/             # Final organized results
├── cache/                   # Temporary files
└── venv/                    # Python virtual environment
```

## 🎯 Running Reconstructions

### Basic Usage

```bash
# Activate the environment
source ~/3d-reconstruction/activate.sh

# Place images in data/images/ or configure Bunny CDN
cp /path/to/your/images/* ~/3d-reconstruction/data/images/

# Run reconstruction
cd ~/3d-reconstruction
./run-reconstruction.sh
```

### Advanced Options

```bash
# High quality (slower)
./run-reconstruction.sh --high-quality

# Fast preview
./run-reconstruction.sh --fast

# Use only local images
./run-reconstruction.sh --local-only

# Force CDN download
./run-reconstruction.sh --cdn-only

# Clean previous results
./run-reconstruction.sh --clean
```

## ☁️ Bunny CDN Configuration

Edit `~/3d-reconstruction/.env` to configure cloud storage:

```bash
# Required for CDN usage
BUNNY_API_KEY=your-api-key-here
BUNNY_STORAGE_ZONE=your-storage-zone-name

# Optional settings
BUNNY_INPUT_PATH=images
BUNNY_OUTPUT_PATH=results
ENABLE_AUTO_UPLOAD=true
```

## ⚙️ Configuration Options

The `.env` file contains extensive configuration options:

### Quality Settings
```bash
GSPLAT_ITERATIONS=30000          # Training iterations (more = higher quality)
ENABLE_DENSE_RECONSTRUCTION=false # Dense reconstruction (slower)
GSPLAT_ENABLE_MCMC=false         # MCMC strategy (experimental)
```

### Performance Settings
```bash
MAX_DOWNLOAD_WORKERS=4           # Parallel downloads
MAX_UPLOAD_WORKERS=2             # Parallel uploads
OMP_NUM_THREADS=16               # CPU threads
```

### COLMAP Settings
```bash
COLMAP_FEATURE_TYPE=sift         # Feature detector
COLMAP_MATCHER_TYPE=exhaustive   # Matching strategy
COLMAP_CAMERA_MODEL=RADIAL       # Camera model
```

## 🔧 Troubleshooting

### Common Issues

**CUDA not available:**
```bash
# Check CUDA installation
nvcc --version
nvidia-smi

# Verify PyTorch CUDA
source ~/3d-reconstruction/activate.sh
python3 -c "import torch; print(torch.cuda.is_available())"
```

**COLMAP not found:**
```bash
# Check COLMAP installation
which colmap
colmap --help | grep CUDA

# Rebuild if needed
./build-deps.sh
```

**Low GPU memory:**
- Reduce `GSPLAT_ITERATIONS` in `.env`
- Use `--fast` option
- Enable `GSPLAT_ENABLE_MCMC=false`

### System Status

```bash
# Check overall system status
~/3d-reconstruction/check-status.sh

# Verify installation
./deploy.sh --verify-only

# Show deployment help
./deploy.sh --help
```

### Log Files

Check logs in `~/3d-reconstruction/logs/` for detailed error information.

## 🎮 Hardware Optimization

### RTX 4090 (Recommended)
- Full pipeline should complete in 15-30 minutes
- Supports all quality features
- 24GB VRAM allows large datasets

### RTX 3080/4080
- Good performance with standard settings
- May need reduced iterations for very large datasets
- 10-16GB VRAM

### Lower-end GPUs (GTX 1080, RTX 2060, etc.)
```bash
# Use these settings in .env
GSPLAT_ITERATIONS=15000
GSPLAT_ENABLE_MCMC=false
ENABLE_DENSE_RECONSTRUCTION=false
```

### CPU-only (No GPU)
- Reconstruction will be significantly slower (hours vs minutes)
- COLMAP feature extraction will be CPU-based
- Some advanced gsplat features may not work

## 📊 Performance Expectations

| Hardware | Small Dataset (50 images) | Medium Dataset (200 images) | Large Dataset (500+ images) |
|----------|---------------------------|------------------------------|----------------------------|
| RTX 4090 | 5-10 minutes | 15-25 minutes | 45-90 minutes |
| RTX 3080 | 10-15 minutes | 25-40 minutes | 60-120 minutes |
| RTX 2080 | 15-25 minutes | 40-70 minutes | 90+ minutes |
| CPU-only | 60-120 minutes | 4-8 hours | 8+ hours |

*Times include COLMAP reconstruction + gsplat training*

## 🔄 Updates and Maintenance

### Updating Dependencies
```bash
# Update gsplat
source ~/3d-reconstruction/activate.sh
pip install --upgrade git+https://github.com/nerfstudio-project/gsplat.git

# Update PyTorch
pip install --upgrade torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu126
```

### Rebuilding COLMAP
```bash
# If you need latest COLMAP features
rm -rf ~/build/colmap
./build-deps.sh
```

## 📝 Script Reference

### Core Scripts
- `deploy.sh` - Complete one-command deployment
- `setup-system.sh` - System dependencies and CUDA
- `build-deps.sh` - COLMAP and Python packages
- `setup-env.sh` - Environment configuration
- `run-reconstruction.sh` - Main reconstruction pipeline

### Helper Scripts
- `scripts/bunny_cdn.py` - CDN upload/download utility
- `scripts/gsplat_trainer.py` - Gaussian splatting training
- `activate.sh` - Environment activation
- `check-status.sh` - System status checker
- `quick-start.sh` - Interactive quick start

## 🐛 Known Issues

1. **CUDA Memory Errors**: Reduce batch size or iterations
2. **COLMAP Reconstruction Fails**: Check image quality and overlap
3. **CDN Upload Timeouts**: Reduce `MAX_UPLOAD_WORKERS`
4. **Permission Errors**: Ensure proper sudo access during setup

## 🤝 Contributing

The deployment scripts are designed to be simple and maintainable:

- Pure bash scripts with minimal dependencies
- Clear logging and error handling
- Modular design for easy customization
- No complex build systems or containers

Feel free to submit issues and improvements!

## 📄 License

This deployment system is provided as-is for educational and research purposes.

---

## 🎯 Example Workflow

Here's a complete example from VM setup to final results:

```bash
# 1. Fresh Ubuntu 24.04 VM setup
sudo apt update && sudo apt upgrade -y

# 2. Deploy the pipeline
git clone <repo> vm-deployment
cd vm-deployment
./deploy.sh

# 3. Configure for your use case
source ~/3d-reconstruction/activate.sh
nano ~/3d-reconstruction/.env  # Add your Bunny CDN keys

# 4. Run reconstruction
cp /path/to/images/* ~/3d-reconstruction/data/images/
cd ~/3d-reconstruction
./run-reconstruction.sh

# 5. View results
ls -la ~/3d-reconstruction/output/results/latest/
```

The results will include:
- `colmap/` - COLMAP sparse reconstruction
- `gaussian/` - Trained Gaussian splat model
- `point_cloud.ply` - Viewable point cloud
- `final_model.pt` - PyTorch model file
- `summary.txt` - Reconstruction statistics

Open the PLY file in MeshLab, CloudCompare, or similar software to visualize your 3D reconstruction!
