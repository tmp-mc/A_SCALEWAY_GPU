# 3D Reconstruction Pipeline - VM Deployment

**Optimized for Ubuntu 24.04 Noble Wombat + NVIDIA L4 GPU (24GB)**

This streamlined deployment script sets up a complete 3D reconstruction pipeline on a VM with pre-installed NVIDIA drivers and CUDA toolkit.

## 🎯 Target Environment

- **OS**: Ubuntu 24.04 LTS (Noble Wombat)
- **GPU**: NVIDIA L4 (24GB VRAM)
- **Architecture**: Ada Lovelace (CUDA Compute Capability 8.9)
- **Prerequisites**: NVIDIA drivers and CUDA toolkit already installed

## 🚀 Quick Start

### 1. Prerequisites Check
Ensure your VM has:
```bash
# Check NVIDIA drivers
nvidia-smi

# Check CUDA (any version is fine)
nvcc --version
# OR check if CUDA is installed anywhere
find /usr -name "nvcc" 2>/dev/null
```

### 2. One-Command Deployment
```bash
cd vm-deployment
chmod +x deploy-vm.sh
./deploy-vm.sh
```

### 3. Activate Environment
```bash
source ~/3d-reconstruction/activate.sh
```

### 4. Check Status
```bash
~/3d-reconstruction/check-status.sh
```

## 📦 What Gets Installed

### System Dependencies
- Build tools (cmake, ninja, gcc)
- Python 3.12 + development headers
- COLMAP dependencies (Boost, Eigen, OpenCV, etc.)

### Python Environment
- **PyTorch** with CUDA 12.x support (auto-detects CUDA version)
- **gsplat** - GPU-accelerated Gaussian splatting
- **Scientific stack** - NumPy, SciPy, OpenCV, etc.
- **3D processing** - Open3D, Trimesh, PLY support

### COLMAP
- Built from source with L4 GPU optimization
- CUDA Architecture 8.9 (Ada Lovelace)
- Full GUI and OpenGL support

## 🎮 L4 GPU Optimizations

The deployment automatically configures:

- **CUDA Architecture**: 8.9 for Ada Lovelace
- **Memory Settings**: Optimized for 24GB VRAM
- **Batch Sizes**: Configured for high-resolution processing
- **Mixed Precision**: Enabled for faster training
- **Image Processing**: Up to 4K resolution support

## 📁 Project Structure

After deployment:
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

## 🔧 Configuration

The deployment creates optimized settings in `~/3d-reconstruction/.env`:

```bash
# L4 GPU Configuration (24GB VRAM)
USE_GPU=true
CUDA_DEVICE=0
GPU_MEMORY_GB=24

# Processing Settings
MAX_IMAGE_SIZE=4096
COLMAP_QUALITY=high
GAUSSIAN_ITERATIONS=30000
BATCH_SIZE=8

# L4 Optimizations
CUDA_MEMORY_FRACTION=0.9
ENABLE_MIXED_PRECISION=true
ENABLE_CUDNN_BENCHMARK=true
```

## 🧪 Usage Examples

### Basic Reconstruction
```bash
# Activate environment
source ~/3d-reconstruction/activate.sh

# Place your images
cp /path/to/images/* ~/3d-reconstruction/data/images/

# Run reconstruction
cd ~/3d-reconstruction
./run-reconstruction.sh
```

### Check System Status
```bash
~/3d-reconstruction/check-status.sh
```

### Manual COLMAP
```bash
source ~/3d-reconstruction/activate.sh
colmap automatic_reconstructor \
    --image_path ~/3d-reconstruction/data/images \
    --workspace_path ~/3d-reconstruction/output/colmap
```

### Python API
```python
# Activate environment first: source ~/3d-reconstruction/activate.sh
import torch
import gsplat

# Check GPU
print(f"CUDA available: {torch.cuda.is_available()}")
print(f"GPU: {torch.cuda.get_device_name(0)}")
print(f"Memory: {torch.cuda.get_device_properties(0).total_memory / 1024**3:.1f}GB")

# Use gsplat for Gaussian splatting
# Your reconstruction code here...
```

## 🔍 Troubleshooting

### Common Issues

**NVIDIA drivers not found**
```bash
# Check if drivers are installed
nvidia-smi
# If not working, install drivers first
```

**CUDA not detected**
```bash
# Find CUDA installation
find /usr -name "nvcc" 2>/dev/null
find /opt -name "nvcc" 2>/dev/null

# Check environment
echo $CUDA_HOME
echo $PATH | grep cuda
```

**PyTorch CUDA not working**
```bash
source ~/3d-reconstruction/activate.sh
python -c "import torch; print(torch.cuda.is_available())"
```

**COLMAP CUDA disabled**
```bash
colmap --help | grep CUDA
# Should show "CUDA enabled"
```

### Verification Commands

```bash
# Full system check
~/3d-reconstruction/check-status.sh

# Verify only
./deploy-vm.sh --verify-only

# Show help
./deploy-vm.sh --help
```

## 📊 Performance Expectations

With L4 GPU (24GB VRAM):

- **Image Processing**: Up to 4K resolution
- **COLMAP**: ~100-500 images in 5-15 minutes
- **Gaussian Splatting**: 30K iterations in 10-30 minutes
- **Memory Usage**: Up to 22GB VRAM utilization
- **Batch Processing**: 8-16 images simultaneously

## 🔄 Updates

To update the pipeline:
```bash
cd vm-deployment
git pull
./deploy-vm.sh  # Re-run deployment
```

## 📞 Support

- **Status Check**: `~/3d-reconstruction/check-status.sh`
- **Logs**: `~/3d-reconstruction/logs/`
- **Configuration**: `~/3d-reconstruction/.env`

## 🏷️ Version Info

- **Target OS**: Ubuntu 24.04 Noble Wombat
- **GPU**: NVIDIA L4 (24GB)
- **CUDA**: Auto-detected (12.x recommended)
- **Python**: 3.12
- **PyTorch**: Latest with CUDA support
- **COLMAP**: Latest from source

---

**Ready for high-performance 3D reconstruction with L4 GPU power! 🚀**
