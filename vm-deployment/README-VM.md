# 3D Reconstruction Pipeline - VM Deployment

This directory contains VM-compatible deployment scripts that work with existing CUDA installations and avoid driver conflicts.

## 🚀 Quick Start (VM)

For VMs with pre-installed CUDA and NVIDIA drivers:

```bash
# One-command deployment
./deploy-vm.sh
```

## 📋 VM Requirements

- **Ubuntu** (any recent version, optimized for 24.04)
- **Pre-installed NVIDIA drivers** (nvidia-smi working)
- **Pre-installed CUDA toolkit** (any version 11.x or 12.x)
- **20+ GB disk space**
- **8+ GB RAM** (16+ GB recommended)
- **Internet connection**
- **Sudo privileges**

## 🔧 VM-Specific Scripts

### Core Scripts

| Script | Purpose | VM-Specific Features |
|--------|---------|---------------------|
| `deploy-vm.sh` | One-command deployment | Uses existing CUDA, no conflicts |
| `setup-system-vm.sh` | System dependencies | Detects existing CUDA installation |
| `build-deps-vm.sh` | Build dependencies | Auto-detects CUDA version & GPU |

### Key Differences from Standard Deployment

| Feature | Standard Scripts | VM Scripts |
|---------|-----------------|------------|
| CUDA Installation | Installs CUDA 12.6 | Uses existing CUDA |
| Driver Management | Installs nvidia-driver-580 | Uses existing drivers |
| PyTorch Version | Fixed to cu126 | Auto-detects (cu117/cu118/cu121) |
| GPU Architecture | Hardcoded for RTX 4090 | Auto-detects from GPU name |
| Compatibility | Ubuntu 24.04 + RTX 4090 | Any Ubuntu + Any CUDA-capable GPU |

## 🛠️ Manual Deployment Steps

If you prefer step-by-step installation:

```bash
# Step 1: System setup (uses existing CUDA)
./setup-system-vm.sh

# Step 2: Reload environment
source ~/.bashrc

# Step 3: Build dependencies (auto-detects CUDA)
./build-deps-vm.sh

# Step 4: Verify installation
source ~/3d-reconstruction/activate.sh
python3 -c "import torch, gsplat; print('Ready!')"
```

## 🔍 CUDA Auto-Detection

The VM scripts automatically detect:

### CUDA Version Mapping
- **CUDA 12.1+** → PyTorch cu121
- **CUDA 12.0** → PyTorch cu118  
- **CUDA 11.8+** → PyTorch cu118
- **CUDA 11.7** → PyTorch cu117
- **Unsupported** → CPU-only PyTorch

### GPU Architecture Detection
- **RTX 4090/4080/4070** → Compute 8.9
- **RTX 3090/3080/3070** → Compute 8.6
- **RTX 2080/2070** → Compute 7.5
- **GTX 1080/1070** → Compute 6.1
- **Tesla V100** → Compute 7.0
- **Tesla T4** → Compute 7.5
- **A100** → Compute 8.0
- **Unknown GPU** → Compute 7.5 (safe default)

## 📊 System Status

Check your VM status after deployment:

```bash
# Comprehensive system check
~/3d-reconstruction/check-vm-status.sh

# Quick environment test
source ~/3d-reconstruction/activate.sh
python3 -c "import torch; print(f'CUDA: {torch.cuda.is_available()}')"
```

## 🐛 Troubleshooting VM Issues

### Common VM Problems

#### 1. CUDA Not Found
```bash
# Check if CUDA is installed
nvcc --version
# or
ls /usr/local/cuda*/bin/nvcc

# If not found, install CUDA on your VM first
```

#### 2. NVIDIA Drivers Missing
```bash
# Check drivers
nvidia-smi

# If not working, install drivers on your VM
sudo ubuntu-drivers autoinstall
sudo reboot
```

#### 3. PyTorch CUDA Not Available
```bash
# Check CUDA compatibility
python3 -c "import torch; print(torch.version.cuda)"
python3 -c "import torch; print(torch.cuda.is_available())"

# Reinstall with correct CUDA version
pip uninstall torch torchvision torchaudio
# VM script will auto-detect and reinstall correct version
```

#### 4. COLMAP Build Fails
```bash
# Check CUDA compiler
which nvcc
$CUDA_HOME/bin/nvcc --version

# Rebuild COLMAP manually
cd ~/build/colmap/build
make clean
cmake .. -DCUDA_ENABLED=ON -DCMAKE_CUDA_ARCHITECTURES="75"
make -j$(nproc)
```

### VM-Specific Debugging

```bash
# Check VM CUDA setup
echo "CUDA_HOME: $CUDA_HOME"
echo "PATH: $PATH"
echo "LD_LIBRARY_PATH: $LD_LIBRARY_PATH"

# Test CUDA compilation
echo 'int main(){return 0;}' > test.cu
nvcc test.cu -o test
./test && echo "CUDA compilation works"
```

## 🔄 Updating VM Installation

To update your VM installation:

```bash
# Update system packages
sudo apt update && sudo apt upgrade

# Rebuild Python environment
rm -rf ~/3d-reconstruction/venv
./build-deps-vm.sh

# Update COLMAP
rm -rf ~/build/colmap
./build-deps-vm.sh
```

## 📁 Project Structure

After VM deployment:

```
~/3d-reconstruction/
├── activate.sh              # Environment activation (VM-compatible)
├── check-vm-status.sh       # VM-specific status checker
├── data/
│   └── images/              # Input images
├── output/
│   ├── colmap/             # COLMAP results
│   ├── gaussian/           # Gaussian splatting results
│   └── results/            # Final outputs
├── venv/                   # Python virtual environment
├── .env                    # Configuration file
└── scripts/                # Pipeline scripts
```

## 🌐 Cloud VM Providers

Tested on:
- **Google Cloud Platform** (with GPU instances)
- **AWS EC2** (with GPU instances)  
- **Azure** (with GPU instances)
- **Paperspace** (with GPU instances)
- **RunPod** (with GPU instances)

## 💡 Performance Tips for VMs

1. **Use GPU instances** - CPU-only will be very slow
2. **Choose adequate memory** - 16GB+ recommended for large reconstructions
3. **Use SSD storage** - Faster I/O for image processing
4. **Monitor GPU memory** - Use `nvidia-smi` to check usage
5. **Optimize batch sizes** - Adjust based on available GPU memory

## 🆘 Getting Help

If you encounter issues:

1. **Check VM status**: `~/3d-reconstruction/check-vm-status.sh`
2. **Verify CUDA**: `nvcc --version && nvidia-smi`
3. **Test environment**: `source ~/3d-reconstruction/activate.sh`
4. **Check logs**: Look for error messages in terminal output
5. **Manual steps**: Try individual scripts if deployment fails

## 📝 Notes

- VM scripts are more flexible but may be slightly slower to deploy
- Auto-detection adds robustness but may not always pick optimal settings
- You can always override detected settings by modifying environment variables
- The VM approach is recommended for cloud deployments and shared systems
