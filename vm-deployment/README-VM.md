# 3D Reconstruction Pipeline - Unified Deployment

**Complete Ubuntu 24.04 + CUDA 12.6 + GPU Setup from Scratch**

This unified deployment script handles everything from system setup to complete 3D reconstruction environment, including fixing common CUDA installation issues.

## 🎯 What This Fixes

**Your CUDA Issues:**
- ❌ `nvcc --version` → Command 'nvcc' not found
- ❌ `systemctl restart nvidia-persistenced.service` → Job failed
- ❌ Incomplete CUDA installations
- ❌ Repository conflicts and keyring issues

**After Running This Script:**
- ✅ `nvcc --version` works properly
- ✅ `nvidia-smi` shows CUDA version
- ✅ nvidia-persistenced service runs correctly
- ✅ PyTorch detects GPU acceleration
- ✅ COLMAP builds with CUDA support

## 🚀 One-Command Solution

### Quick Start
```bash
cd vm-deployment
chmod +x deploy-vm.sh
./deploy-vm.sh
```

That's it! The script handles everything:
- Complete CUDA cleanup and fresh installation
- NVIDIA driver fixes and service configuration
- Python environment with GPU-accelerated packages
- COLMAP build with GPU optimization
- Project structure and configuration

## 📦 Complete Installation Includes

### System Setup
- Ubuntu 24.04 compatibility checks
- System updates and essential build tools
- Complete CUDA 12.6 installation from scratch
- NVIDIA driver installation and service fixes

### CUDA Environment
- **Complete cleanup** of existing installations
- **Fresh CUDA 12.6** installation with proper keyring
- **Environment configuration** (CUDA_HOME, PATH, LD_LIBRARY_PATH)
- **Service fixes** for nvidia-persistenced
- **Verification** that nvcc and nvidia-smi work

### Python Environment
- **Python 3.12** virtual environment
- **PyTorch** with CUDA 12.x support
- **gsplat** - GPU-accelerated Gaussian splatting
- **Scientific stack** - NumPy, SciPy, OpenCV, etc.
- **3D processing** - Open3D, Trimesh, PLY support

### COLMAP
- Built from source with GPU optimization
- CUDA Architecture 8.9 (RTX 4090/L4 GPU)
- Full GUI and OpenGL support
- Verified CUDA integration

## 🔧 Advanced Options

```bash
# Show help and options
./deploy-vm.sh --help

# Only cleanup existing CUDA (useful for troubleshooting)
./deploy-vm.sh --cleanup-only

# Only run verification tests
./deploy-vm.sh --verify-only

# Show system status
./deploy-vm.sh --status
```

## 📁 Project Structure After Deployment

```
~/3d-reconstruction/
├── activate.sh              # Environment activation
├── check-status.sh          # System status check
├── venv/                    # Python virtual environment
├── data/
│   ├── images/             # Input images
│   └── models/             # 3D models
├── output/
│   ├── colmap/             # COLMAP results
│   ├── gaussian/           # Gaussian splatting
│   └── results/            # Final outputs
├── cache/                   # Processing cache
├── logs/                    # System logs
├── scripts/                 # Pipeline scripts
├── .env                     # Configuration
└── run-reconstruction.sh    # Main pipeline
```

## 🎮 GPU Optimizations

The deployment automatically configures:

- **CUDA Architecture**: 8.9 for RTX 4090/L4 GPU
- **Memory Settings**: Auto-detected GPU memory optimization
- **Batch Sizes**: Configured for high-resolution processing
- **Mixed Precision**: Enabled for faster training
- **Service Fixes**: nvidia-persistenced properly configured

## 🧪 Usage Examples

### Activate Environment
```bash
source ~/3d-reconstruction/activate.sh
```

### Check System Status
```bash
~/3d-reconstruction/check-status.sh
```

### Verify CUDA Installation
```bash
# These should all work after deployment
nvcc --version
nvidia-smi
python -c "import torch; print(torch.cuda.is_available())"
colmap --help | grep CUDA
```

### Run Reconstruction
```bash
# Place your images
cp /path/to/images/* ~/3d-reconstruction/data/images/

# Run reconstruction
cd ~/3d-reconstruction
./run-reconstruction.sh
```

## 🔍 Troubleshooting Your Original Issues

### nvidia-persistenced Service
**Before:** `Job for nvidia-persistenced.service failed`
**After:** Service runs correctly with proper user and permissions

**What the script fixes:**
- Creates nvidia-persistenced user if missing
- Sets proper directory permissions
- Configures service dependencies

### nvcc Command Not Found
**Before:** `Command 'nvcc' not found, but can be installed with: apt install nvidia-cuda-toolkit`
**After:** `nvcc --version` shows CUDA 12.6

**What the script fixes:**
- Complete CUDA cleanup removes conflicting installations
- Fresh CUDA 12.6 installation with official repositories
- Proper PATH and environment variable configuration
- Symlink creation for standard CUDA paths

### Repository Conflicts
**Before:** Package conflicts and keyring issues
**After:** Clean installation with proper repositories

**What the script fixes:**
- Removes all conflicting CUDA repositories
- Cleans up old keyrings and cached packages
- Installs fresh keyring from NVIDIA
- Updates package lists properly

## 📊 Performance Expectations

With RTX 4090/L4 GPU:
- **Image Processing**: Up to 4K resolution
- **COLMAP**: ~100-500 images in 5-15 minutes
- **Gaussian Splatting**: 30K iterations in 10-30 minutes
- **Memory Usage**: Optimized for available GPU memory
- **Batch Processing**: Auto-configured batch sizes

## 🔄 System Requirements

- **OS**: Ubuntu 24.04 LTS (Noble Wombat)
- **GPU**: NVIDIA GPU (RTX 4090/L4 optimized)
- **RAM**: 8+ GB (16+ GB recommended)
- **Storage**: 30+ GB available space
- **Network**: Internet connection required
- **Privileges**: Sudo access needed

## ⏱️ Installation Time

- **Complete deployment**: 20-45 minutes
- **CUDA installation**: 10-15 minutes
- **Python packages**: 5-10 minutes
- **COLMAP build**: 10-20 minutes

## 🆘 Support

If deployment fails:

1. **Check logs**: The script provides detailed error messages
2. **Run status check**: `~/3d-reconstruction/check-status.sh`
3. **Verify prerequisites**: Ensure Ubuntu 24.04 and sufficient resources
4. **Clean retry**: Use `./deploy-vm.sh --cleanup-only` then retry

## 🏷️ What's Different

**Old approach (multiple scripts):**
- `setup-system.sh` - System setup
- `build-deps.sh` - Dependencies
- `deploy-vm.sh` - VM-specific deployment
- Multiple points of failure

**New approach (single script):**
- `deploy-vm.sh` - Everything in one script
- Comprehensive error handling
- Complete CUDA cleanup and installation
- Fixes your specific nvidia-persistenced and nvcc issues

---

**Ready to fix your CUDA issues and set up complete 3D reconstruction! 🚀**

Run `./deploy-vm.sh` and watch it solve your nvcc and nvidia-persistenced problems automatically.
