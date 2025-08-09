# 3D Reconstruction Pipeline - GPU Deployment

🚀 **One-Command Setup** for Ubuntu 24.04 VMs with NVIDIA GPUs

## Quick Start

```bash
curl -sSL https://github.com/tmp-mc/A_SCRIPT_GPU/releases/latest/download/deploy.tar.gz | tar -xz && cd A_SCRIPT_GPU && ./deploy.sh
```

That's it! The script will automatically:
- Install CUDA 12.6 and GPU drivers
- Build COLMAP with CUDA support  
- Set up Python environment with PyTorch and gsplat
- Create complete project structure
- Optionally configure Bunny CDN at the end

## Requirements

- **OS**: Ubuntu 24.04 LTS (fresh VM)
- **GPU**: NVIDIA GPU recommended (RTX 4090 optimized)
- **Disk**: 30+ GB available space
- **RAM**: 8+ GB (16+ GB recommended)
- **Access**: sudo privileges

## What You Get

Complete 3D reconstruction pipeline in `~/3d-reconstruction/`:
- **COLMAP**: Structure from Motion with CUDA acceleration
- **Gaussian Splatting**: Web-optimized training system
- **Bunny CDN**: Optional cloud storage integration
- **Ready-to-use**: One command to run reconstructions

## After Installation

```bash
# Activate environment
source ~/3d-reconstruction/activate.sh

# Place images and run reconstruction
cp /path/to/images/* ~/3d-reconstruction/data/images/
cd ~/3d-reconstruction
./run-reconstruction.sh
```

## Documentation

📖 **Detailed documentation**: See [`vm-deployment/README.md`](vm-deployment/README.md) for complete configuration options, troubleshooting, and advanced usage.

## Troubleshooting

**CUDA Issues**: Ensure you have a compatible NVIDIA GPU and driver support
**Permission Errors**: Make sure you have sudo access during setup
**Out of Space**: Ensure 30+ GB free disk space before installation

---

**Deployment Time**: 30-60 minutes depending on internet speed and hardware
**Reconstruction Time**: 5-30 minutes depending on dataset size and GPU
