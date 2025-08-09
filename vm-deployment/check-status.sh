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
    echo "   Version: $(colmap help 2>&1 | head -1 | grep -o 'COLMAP [0-9.]*' || echo 'Available')"
    echo "   CUDA: $(colmap help 2>&1 | grep -q "CUDA" && echo "✅ Enabled" || echo "❌ Disabled")"
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
