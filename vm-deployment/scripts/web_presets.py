#!/usr/bin/env python3
"""
Web-Optimized gsplat Training Presets
Comprehensive configuration system for web application integration
"""

from dataclasses import dataclass, field
from typing import Dict, Any, Optional, Tuple
import torch

@dataclass
class ParameterDoc:
    """Documentation for training parameters"""
    description: str
    web_impact: str  # Impact on web performance/quality/size
    range_info: str  # Valid range and recommendations
    trade_offs: str  # Performance vs quality trade-offs

@dataclass 
class WebTrainingConfig:
    """Enhanced configuration for web-optimized gsplat training"""
    
    # === CORE TRAINING ===
    iterations: int = 30000
    save_interval: int = 5000
    eval_interval: int = 1000
    
    # === WEB OPTIMIZATION ===
    target_file_size_mb: float = 50.0  # Target output file size
    quality_target_psnr: float = 28.0  # Auto-stop when reached
    compression_enabled: bool = True
    streaming_support: bool = False
    
    # === STRATEGY SELECTION ===
    strategy: str = "adaptive"  # adaptive, mcmc, default, compression_focused
    gaussian_capacity: int = 1000000  # Max gaussians (file size impact)
    
    # === QUALITY FEATURES ===
    use_absgrad: bool = True
    use_antialiasing: bool = True
    use_progressive_training: bool = True
    
    # === RENDERING OPTIMIZATION ===
    render_mode: str = "antialiased"  # classic, antialiased
    tile_size: int = 16
    radius_clip: float = 0.0  # Skip small gaussians (web performance)
    feature_dimensions: int = 3  # RGB=3, extended features=32
    
    # === MULTI-GPU ===
    distributed: bool = True
    sparse_grad: bool = False
    
    # === LEARNING RATES ===
    lr_means: float = 0.00016
    lr_scales: float = 0.005
    lr_quats: float = 0.001
    lr_opacities: float = 0.05
    lr_sh0: float = 0.25
    
    # === DENSIFICATION ===
    densify_grad_threshold: float = 0.0002
    densify_start_iter: int = 500
    densify_stop_iter: int = 15000
    opacity_reset_interval: int = 3000
    prune_opacity: float = 0.005
    
    # === EXPORT OPTIONS ===
    save_ply: bool = True
    save_compressed: bool = True
    save_streaming: bool = False
    export_quality_report: bool = True
    
    # Documentation mapping
    docs: Dict[str, ParameterDoc] = field(default_factory=lambda: PARAMETER_DOCS)
    
    def get_strategy_config(self) -> Dict[str, Any]:
        """Get strategy-specific configuration"""
        if self.strategy == "mcmc":
            return {
                "type": "mcmc",
                "cap_max": self.gaussian_capacity,
                "refine_start_iter": self.densify_start_iter,
                "refine_stop_iter": self.densify_stop_iter,
                "min_opacity": self.prune_opacity
            }
        elif self.strategy == "compression_focused":
            return {
                "type": "default",
                "prune_opa": 0.01,  # More aggressive pruning
                "grow_grad2d": 0.0004,  # Higher threshold
                "refine_stop_iter": 10000,  # Earlier stop
                "absgrad": False
            }
        elif self.strategy == "adaptive":
            # Choose based on target file size
            if self.target_file_size_mb < 25:
                return self._get_compression_config()
            elif self.target_file_size_mb > 100:
                return self._get_quality_config()
            else:
                return self._get_balanced_config()
        else:  # default
            return {
                "type": "default",
                "prune_opa": self.prune_opacity,
                "grow_grad2d": self.densify_grad_threshold,
                "absgrad": self.use_absgrad
            }
    
    def _get_compression_config(self) -> Dict[str, Any]:
        """Aggressive compression settings"""
        return {
            "type": "default",
            "prune_opa": 0.01,
            "grow_grad2d": 0.0004,
            "refine_stop_iter": 10000,
            "gaussian_cap": min(500000, self.gaussian_capacity),
            "absgrad": False
        }
    
    def _get_quality_config(self) -> Dict[str, Any]:
        """High quality settings"""
        return {
            "type": "mcmc",
            "cap_max": self.gaussian_capacity,
            "refine_stop_iter": 25000,
            "absgrad": True
        }
    
    def _get_balanced_config(self) -> Dict[str, Any]:
        """Balanced quality/size settings"""
        return {
            "type": "default",
            "prune_opa": self.prune_opacity,
            "grow_grad2d": 0.0006 if self.use_absgrad else 0.0002,
            "absgrad": self.use_absgrad
        }
    
    def estimate_metrics(self) -> Dict[str, Any]:
        """Estimate training time and output characteristics"""
        # Rough estimates based on gsplat benchmarks
        base_time_minutes = self.iterations / 1000 * 1.2  # ~1.2min per 1k iterations
        
        if self.distributed and torch.cuda.device_count() > 1:
            base_time_minutes /= min(4, torch.cuda.device_count())
        
        # File size estimation (very rough)
        base_size_mb = self.gaussian_capacity / 1000000 * 236  # ~236MB per 1M gaussians
        if self.compression_enabled:
            base_size_mb *= 0.07  # PNG compression ratio
        
        return {
            "estimated_training_time_minutes": int(base_time_minutes),
            "estimated_file_size_mb": min(base_size_mb, self.target_file_size_mb * 1.5),
            "expected_psnr_range": self._estimate_quality_range(),
            "memory_usage_gb": self._estimate_memory_usage(),
            "web_performance": self._estimate_web_performance()
        }
    
    def _estimate_quality_range(self) -> Tuple[float, float]:
        """Estimate PSNR range based on configuration"""
        if self.strategy == "mcmc" and self.gaussian_capacity >= 2000000:
            return (29.2, 29.7)
        elif self.use_absgrad and self.use_antialiasing:
            return (28.8, 29.2)
        elif self.strategy == "compression_focused":
            return (27.5, 28.5)
        else:
            return (28.0, 29.0)
    
    def _estimate_memory_usage(self) -> float:
        """Estimate GPU memory usage in GB"""
        base_memory = 3.0  # Base gsplat overhead
        gaussian_memory = self.gaussian_capacity / 1000000 * 2.0  # ~2GB per 1M gaussians
        
        if self.distributed:
            gaussian_memory /= min(4, torch.cuda.device_count())
        
        return base_memory + gaussian_memory
    
    def _estimate_web_performance(self) -> str:
        """Estimate web application performance"""
        size_score = 1.0 - min(1.0, self.target_file_size_mb / 100)
        quality_score = (self.quality_target_psnr - 25) / 10
        
        overall = (size_score + quality_score) / 2
        
        if overall > 0.8:
            return "Excellent - Fast loading, high quality"
        elif overall > 0.6:
            return "Good - Balanced loading/quality"
        elif overall > 0.4:
            return "Fair - Slower loading or lower quality"
        else:
            return "Poor - Large files or low quality"


# Parameter documentation with web impact
PARAMETER_DOCS = {
    "iterations": ParameterDoc(
        "Number of training iterations",
        "Higher = better quality but longer training time",
        "7000-30000, recommend 15000 for web, 30000 for premium",
        "Time vs Quality: 7k=fast/ok, 15k=medium/good, 30k=slow/excellent"
    ),
    
    "gaussian_capacity": ParameterDoc(
        "Maximum number of 3D Gaussians in final model",
        "Directly affects file size - most critical web parameter",
        "100k-3M, recommend 500k=mobile, 1M=desktop, 2M+=premium",
        "Size vs Quality: 100k=tiny/basic, 1M=medium/good, 3M=large/excellent"
    ),
    
    "use_absgrad": ParameterDoc(
        "Use absolute gradients for better gaussian splitting",
        "Better geometry detail, reduces gaussian count for same quality",
        "true/false, recommend true for most cases",
        "Quality vs Speed: false=faster, true=better geometry"
    ),
    
    "use_antialiasing": ParameterDoc(
        "Anti-aliased rendering with opacity compensation", 
        "Smoother visuals, especially important for web viewing",
        "true/false, recommend true for web applications",
        "Quality vs Speed: false=faster render, true=smoother visuals"
    ),
    
    "radius_clip": ParameterDoc(
        "Skip gaussians smaller than this pixel threshold",
        "Critical for web performance - culls distant/small gaussians",
        "0.0-3.0, recommend 0.5-1.0 for web, 0.0 for quality",
        "Performance vs Quality: 0=all gaussians, 2.0=aggressive culling"
    ),
    
    "compression_enabled": ParameterDoc(
        "Enable PNG compression for web deployment",
        "Reduces file size by ~90% with minimal quality loss",
        "true/false, recommend true for web",
        "Size vs Quality: ~16MB vs 236MB, 0.5dB PSNR loss"
    ),
    
    "strategy": ParameterDoc(
        "Training strategy selection",
        "Affects final quality, file size, and training time",
        "adaptive/mcmc/default/compression_focused",
        "mcmc=best quality, default=balanced, compression_focused=smallest files"
    ),
    
    "target_file_size_mb": ParameterDoc(
        "Target output file size for web deployment",
        "Automatically adjusts parameters to meet size constraints",
        "5-200MB, recommend 10MB=mobile, 50MB=desktop, 100MB+=premium",
        "Automatically balances quality vs size to meet target"
    ),
    
    "quality_target_psnr": ParameterDoc(
        "Auto-stop training when PSNR target is reached",
        "Prevents overtraining and saves time for web deployment",
        "25-32dB, recommend 27=basic, 28=good, 29+=premium",
        "Higher targets = longer training but better visuals"
    ),
    
    "distributed": ParameterDoc(
        "Multi-GPU distributed training",
        "Reduces training time dramatically for large models",
        "true/false, auto-detected based on available GPUs",
        "Speed vs Setup: 4x faster training but requires multi-GPU setup"
    ),
    
    "tile_size": ParameterDoc(
        "Rasterization tile size (advanced)",
        "Affects rendering performance and memory usage",
        "8-32, recommend 16 for most cases",
        "Memory vs Speed: 8=less memory, 32=potentially faster"
    )
}


# Web-optimized presets
WEB_PRESETS = {
    "mobile": WebTrainingConfig(
        # Ultra-compressed for mobile web
        iterations=12000,
        gaussian_capacity=300000,
        target_file_size_mb=8.0,
        quality_target_psnr=27.0,
        strategy="compression_focused",
        use_absgrad=False,
        use_antialiasing=True,
        radius_clip=1.0,
        densify_stop_iter=8000,
        save_streaming=False
    ),
    
    "desktop": WebTrainingConfig(
        # Balanced for desktop web
        iterations=20000,
        gaussian_capacity=1000000,
        target_file_size_mb=35.0,
        quality_target_psnr=28.5,
        strategy="adaptive",
        use_absgrad=True,
        use_antialiasing=True,
        radius_clip=0.5,
        save_streaming=True
    ),
    
    "premium": WebTrainingConfig(
        # High quality for premium web experiences
        iterations=30000,
        gaussian_capacity=2500000,
        target_file_size_mb=80.0,
        quality_target_psnr=29.5,
        strategy="mcmc",
        use_absgrad=True,
        use_antialiasing=True,
        radius_clip=0.0,
        densify_stop_iter=25000,
        save_streaming=True,
        use_progressive_training=True
    ),
    
    "custom": WebTrainingConfig()  # Full parameter control
}


def get_preset(preset_name: str) -> WebTrainingConfig:
    """Get a web-optimized training preset"""
    if preset_name not in WEB_PRESETS:
        print(f"❌ Unknown preset '{preset_name}'. Available: {list(WEB_PRESETS.keys())}")
        return WEB_PRESETS["desktop"]  # Safe default
    
    preset = WEB_PRESETS[preset_name]
    print(f"🎯 Loaded preset: {preset_name}")
    
    # Show estimates
    estimates = preset.estimate_metrics()
    print(f"   📊 Estimated training: {estimates['estimated_training_time_minutes']}min")
    print(f"   📁 Estimated file size: {estimates['estimated_file_size_mb']:.1f}MB")
    print(f"   🎨 Expected PSNR: {estimates['expected_psnr_range'][0]:.1f}-{estimates['expected_psnr_range'][1]:.1f}dB")
    print(f"   💾 Memory usage: {estimates['memory_usage_gb']:.1f}GB")
    print(f"   🌐 Web performance: {estimates['web_performance']}")
    
    return preset


def print_parameter_help(param_name: str = None):
    """Print detailed parameter documentation"""
    if param_name:
        if param_name in PARAMETER_DOCS:
            doc = PARAMETER_DOCS[param_name]
            print(f"\n📖 {param_name}:")
            print(f"   Purpose: {doc.description}")
            print(f"   Web Impact: {doc.web_impact}")
            print(f"   Range: {doc.range_info}")
            print(f"   Trade-offs: {doc.trade_offs}")
        else:
            print(f"❌ No documentation for parameter '{param_name}'")
    else:
        print("📚 Available parameters:")
        for param in PARAMETER_DOCS:
            print(f"   {param}")
        print("\nUse print_parameter_help('parameter_name') for details")


if __name__ == "__main__":
    # Demo the preset system
    print("🎯 gsplat Web Training Presets")
    print("=" * 40)
    
    for preset_name in WEB_PRESETS:
        print(f"\n{preset_name.upper()}:")
        preset = get_preset(preset_name)
        print()
