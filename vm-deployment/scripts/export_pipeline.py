#!/usr/bin/env python3
"""
Web-Optimized Export Pipeline for gsplat
Handles compression, streaming, and web-ready format generation
"""

import os
import json
import time
from pathlib import Path
from typing import Dict, Any, Optional, Tuple, List
import numpy as np
import torch

try:
    from gsplat.compression import PngCompression
    import imageio
except ImportError:
    print("❌ Missing dependencies. Run: pip install imageio")


class WebExportPipeline:
    """Comprehensive export pipeline for web deployment"""
    
    def __init__(self, output_path: Path, config: Dict[str, Any]):
        self.output_path = Path(output_path)
        self.config = config
        
        # Create output structure
        self.create_output_structure()
        
    def create_output_structure(self):
        """Create organized output directory structure"""
        dirs = [
            "models/compressed",    # Web-ready compressed files
            "models/full",         # Uncompressed originals
            "models/streaming",    # Progressive loading files
            "metrics",             # Quality and performance reports
            "web_config",          # Web integration settings
            "exports"              # Various export formats
        ]
        
        for dir_path in dirs:
            (self.output_path / dir_path).mkdir(parents=True, exist_ok=True)
    
    def export_all_formats(self, gaussians: Dict[str, torch.Tensor], 
                          training_metrics: Dict[str, Any]) -> Dict[str, Path]:
        """Export gaussians in all web-ready formats"""
        print("📦 Starting web export pipeline...")
        
        exports = {}
        start_time = time.time()
        
        # 1. Standard PLY format
        if self.config.get('save_ply', True):
            ply_path = self.export_ply(gaussians)
            exports['ply'] = ply_path
            print(f"✅ PLY exported: {ply_path.name}")
        
        # 2. Compressed format for web
        if self.config.get('save_compressed', True):
            compressed_path = self.export_compressed(gaussians)
            exports['compressed'] = compressed_path
            print(f"✅ Compressed exported: {compressed_path.name}")
        
        # 3. Streaming format for progressive loading
        if self.config.get('save_streaming', False):
            streaming_path = self.export_streaming(gaussians)
            exports['streaming'] = streaming_path
            print(f"✅ Streaming exported: {streaming_path.name}")
        
        # 4. Web configuration files
        web_config_path = self.export_web_config(gaussians, training_metrics)
        exports['web_config'] = web_config_path
        
        # 5. Quality report
        if self.config.get('export_quality_report', True):
            report_path = self.export_quality_report(gaussians, training_metrics)
            exports['quality_report'] = report_path
        
        # 6. Integration examples
        examples_path = self.generate_integration_examples(exports)
        exports['examples'] = examples_path
        
        export_time = time.time() - start_time
        print(f"🎯 Export pipeline completed in {export_time:.1f}s")
        
        return exports
    
    def export_ply(self, gaussians: Dict[str, torch.Tensor]) -> Path:
        """Export standard PLY format"""
        output_path = self.output_path / "exports" / "gaussian_splats.ply"
        
        means = gaussians['means'].detach().cpu().numpy()
        colors = gaussians.get('sh0', gaussians.get('colors')).detach().cpu().numpy()
        scales = gaussians['scales'].detach().cpu().numpy()
        quats = gaussians['quats'].detach().cpu().numpy()
        opacities = gaussians['opacities'].detach().cpu().numpy()
        
        # Ensure colors are in [0,1] range
        colors = np.clip(colors, 0, 1)
        
        # Convert to standard PLY format
        with open(output_path, 'w') as f:
            f.write("ply\n")
            f.write("format ascii 1.0\n")
            f.write(f"element vertex {len(means)}\n")
            f.write("property float x\n")
            f.write("property float y\n")
            f.write("property float z\n")
            f.write("property float nx\n")  # Normal x (using quat)
            f.write("property float ny\n")  # Normal y
            f.write("property float nz\n")  # Normal z
            f.write("property uchar red\n")
            f.write("property uchar green\n")
            f.write("property uchar blue\n")
            f.write("property float scale_x\n")
            f.write("property float scale_y\n")
            f.write("property float scale_z\n")
            f.write("property float opacity\n")
            f.write("end_header\n")
            
            for i in range(len(means)):
                x, y, z = means[i]
                r, g, b = (colors[i] * 255).astype(int)
                sx, sy, sz = scales[i]
                qw, qx, qy, qz = quats[i]  # Use quaternion as normal approximation
                opacity = opacities[i]
                
                f.write(f"{x} {y} {z} {qx} {qy} {qz} {r} {g} {b} {sx} {sy} {sz} {opacity}\n")
        
        return output_path
    
    def export_compressed(self, gaussians: Dict[str, torch.Tensor]) -> Path:
        """Export PNG-compressed format for web"""
        compressed_dir = self.output_path / "models" / "compressed"
        
        try:
            # Use gsplat's PNG compression
            compressor = PngCompression(verbose=True)
            
            # Prepare gaussians in expected format
            splats_dict = {
                'means': gaussians['means'],
                'scales': gaussians['scales'], 
                'quats': gaussians['quats'],
                'opacities': gaussians['opacities'],
                'sh0': gaussians.get('sh0', gaussians.get('colors')),
                'shN': torch.zeros_like(gaussians.get('sh0', gaussians.get('colors')))  # Placeholder
            }
            
            # Add any additional features
            for key, value in gaussians.items():
                if key not in splats_dict:
                    splats_dict[key] = value
            
            # Compress
            compressor.compress(str(compressed_dir), splats_dict)
            
            print(f"   📊 Compressed {len(gaussians['means']):,} gaussians")
            return compressed_dir
            
        except Exception as e:
            print(f"⚠️  PNG compression failed: {e}")
            # Fallback to standard pytorch save
            fallback_path = compressed_dir / "fallback.pt"
            torch.save(gaussians, fallback_path)
            return fallback_path
    
    def export_streaming(self, gaussians: Dict[str, torch.Tensor]) -> Path:
        """Export streaming format for progressive loading"""
        streaming_dir = self.output_path / "models" / "streaming"
        
        # Sort gaussians by importance (opacity * scale)
        opacities = gaussians['opacities'].detach().cpu()
        scales = gaussians['scales'].detach().cpu().norm(dim=1)
        importance = opacities * scales
        
        # Sort by importance (descending)
        sorted_indices = torch.argsort(importance, descending=True)
        
        # Create progressive chunks
        chunk_sizes = [1000, 5000, 25000, 100000]  # Progressive loading levels
        current_idx = 0
        
        for i, chunk_size in enumerate(chunk_sizes):
            if current_idx >= len(sorted_indices):
                break
                
            end_idx = min(current_idx + chunk_size, len(sorted_indices))
            chunk_indices = sorted_indices[current_idx:end_idx]
            
            # Extract chunk
            chunk = {}
            for key, value in gaussians.items():
                chunk[key] = value[chunk_indices]
            
            # Save chunk
            chunk_path = streaming_dir / f"chunk_{i:02d}.pt"
            torch.save(chunk, chunk_path)
            
            print(f"   📦 Chunk {i}: {len(chunk_indices):,} gaussians")
            current_idx = end_idx
        
        # Create streaming manifest
        manifest = {
            'total_gaussians': len(sorted_indices),
            'chunks': [f"chunk_{i:02d}.pt" for i in range(len(chunk_sizes))],
            'chunk_sizes': chunk_sizes[:len(chunk_sizes)],
            'loading_strategy': 'progressive_importance'
        }
        
        manifest_path = streaming_dir / "manifest.json"
        with open(manifest_path, 'w') as f:
            json.dump(manifest, f, indent=2)
        
        return streaming_dir
    
    def export_web_config(self, gaussians: Dict[str, torch.Tensor], 
                         training_metrics: Dict[str, Any]) -> Path:
        """Generate web integration configuration"""
        config_dir = self.output_path / "web_config"
        
        # Calculate model statistics
        num_gaussians = len(gaussians['means'])
        means = gaussians['means'].detach().cpu()
        bounds = {
            'min': means.min(dim=0)[0].tolist(),
            'max': means.max(dim=0)[0].tolist(),
            'center': means.mean(dim=0).tolist()
        }
        
        # Estimate file sizes
        uncompressed_size = sum(tensor.numel() * tensor.element_size() 
                              for tensor in gaussians.values())
        estimated_compressed = uncompressed_size * 0.07  # PNG compression ratio
        
        web_config = {
            'model_info': {
                'num_gaussians': num_gaussians,
                'bounds': bounds,
                'estimated_size_mb': {
                    'uncompressed': uncompressed_size / 1024 / 1024,
                    'compressed': estimated_compressed / 1024 / 1024
                }
            },
            'performance': {
                'expected_fps': self._estimate_render_fps(num_gaussians),
                'memory_usage_mb': self._estimate_runtime_memory(num_gaussians),
                'recommended_settings': self._get_render_recommendations(num_gaussians)
            },
            'training_info': training_metrics,
            'web_integration': {
                'loading_strategy': 'compressed' if estimated_compressed < 50*1024*1024 else 'streaming',
                'cache_settings': {
                    'enable_browser_cache': True,
                    'cache_duration_hours': 24
                },
                'fallback_options': {
                    'low_quality_threshold': 100000,  # Switch to simpler rendering
                    'mobile_optimization': True
                }
            }
        }
        
        config_path = config_dir / "web_config.json"
        with open(config_path, 'w') as f:
            json.dump(web_config, f, indent=2)
        
        return config_path
    
    def export_quality_report(self, gaussians: Dict[str, torch.Tensor], 
                             training_metrics: Dict[str, Any]) -> Path:
        """Generate comprehensive quality report"""
        report_path = self.output_path / "metrics" / "quality_report.json"
        
        # Analyze gaussian distribution
        means = gaussians['means'].detach().cpu()
        scales = gaussians['scales'].detach().cpu()
        opacities = gaussians['opacities'].detach().cpu()
        
        report = {
            'model_statistics': {
                'total_gaussians': len(means),
                'active_gaussians': (opacities > 0.01).sum().item(),
                'average_opacity': opacities.mean().item(),
                'scale_distribution': {
                    'mean': scales.mean().item(),
                    'std': scales.std().item(),
                    'min': scales.min().item(),
                    'max': scales.max().item()
                }
            },
            'quality_metrics': training_metrics.get('final_metrics', {}),
            'web_readiness': {
                'file_size_score': self._score_file_size(len(means)),
                'performance_score': self._score_performance(len(means)),
                'quality_score': self._score_quality(training_metrics),
                'overall_score': 0  # Will be calculated
            },
            'recommendations': self._generate_recommendations(gaussians, training_metrics)
        }
        
        # Calculate overall score
        scores = report['web_readiness']
        scores['overall_score'] = (scores['file_size_score'] + 
                                 scores['performance_score'] + 
                                 scores['quality_score']) / 3
        
        with open(report_path, 'w') as f:
            json.dump(report, f, indent=2)
        
        return report_path
    
    def generate_integration_examples(self, exports: Dict[str, Path]) -> Path:
        """Generate web integration code examples"""
        examples_dir = self.output_path / "web_config" / "examples"
        examples_dir.mkdir(exist_ok=True)
        
        # Three.js integration example
        threejs_example = '''
// Three.js Gaussian Splatting Integration Example
import * as THREE from 'three';

class GaussianSplatsLoader {
    constructor(scene, camera, renderer) {
        this.scene = scene;
        this.camera = camera;
        this.renderer = renderer;
        this.gaussianMesh = null;
    }
    
    async loadCompressed(url) {
        try {
            const response = await fetch(url);
            const data = await response.arrayBuffer();
            
            // Parse compressed gaussian data
            const gaussians = this.parseCompressedData(data);
            
            // Create Three.js representation
            this.gaussianMesh = this.createGaussianMesh(gaussians);
            this.scene.add(this.gaussianMesh);
            
            return this.gaussianMesh;
        } catch (error) {
            console.error('Failed to load gaussian splats:', error);
            return null;
        }
    }
    
    createGaussianMesh(gaussians) {
        const geometry = new THREE.BufferGeometry();
        
        geometry.setAttribute('position', 
            new THREE.Float32BufferAttribute(gaussians.means, 3));
        geometry.setAttribute('color', 
            new THREE.Float32BufferAttribute(gaussians.colors, 3));
        geometry.setAttribute('scale', 
            new THREE.Float32BufferAttribute(gaussians.scales, 3));
        geometry.setAttribute('opacity', 
            new THREE.Float32BufferAttribute(gaussians.opacities, 1));
        
        const material = new THREE.PointsMaterial({
            size: 0.1,
            vertexColors: true,
            transparent: true,
            blending: THREE.AdditiveBlending
        });
        
        return new THREE.Points(geometry, material);
    }
    
    parseCompressedData(buffer) {
        // Implementation depends on compression format
        // This is a placeholder for actual parsing
        return {
            means: new Float32Array(),
            colors: new Float32Array(),
            scales: new Float32Array(),
            opacities: new Float32Array()
        };
    }
}

// Usage
const loader = new GaussianSplatsLoader(scene, camera, renderer);
loader.loadCompressed('/models/compressed/gaussians.compressed');
        '''
        
        # WebGL shader example
        webgl_shader = '''
// WebGL Gaussian Splatting Vertex Shader
attribute vec3 position;
attribute vec3 color;
attribute vec3 scale;
attribute float opacity;

uniform mat4 modelViewMatrix;
uniform mat4 projectionMatrix;
uniform vec2 viewport;

varying vec3 vColor;
varying float vOpacity;
varying vec2 vUv;

void main() {
    vec4 mvPosition = modelViewMatrix * vec4(position, 1.0);
    
    // Project to screen space
    vec4 projectedPosition = projectionMatrix * mvPosition;
    gl_Position = projectedPosition;
    
    // Calculate gaussian size based on scale and distance
    float distance = length(mvPosition.xyz);
    gl_PointSize = scale.x * viewport.y / distance;
    
    vColor = color;
    vOpacity = opacity;
}

// Fragment Shader
precision mediump float;

varying vec3 vColor;
varying float vOpacity;

void main() {
    vec2 uv = gl_PointCoord.xy - 0.5;
    float dist = dot(uv, uv);
    
    // Gaussian falloff
    float alpha = exp(-4.0 * dist) * vOpacity;
    
    if (alpha < 0.01) discard;
    
    gl_FragColor = vec4(vColor, alpha);
}
        '''
        
        # Save examples
        with open(examples_dir / "threejs_integration.js", 'w') as f:
            f.write(threejs_example)
            
        with open(examples_dir / "webgl_shaders.glsl", 'w') as f:
            f.write(webgl_shader)
        
        # HTML demo page
        html_demo = f'''
<!DOCTYPE html>
<html>
<head>
    <title>Gaussian Splats Web Demo</title>
    <style>
        body {{ margin: 0; background: #000; }}
        canvas {{ display: block; }}
        #info {{ position: absolute; top: 10px; left: 10px; color: white; }}
    </style>
</head>
<body>
    <div id="info">
        <h3>Gaussian Splats Demo</h3>
        <p>Gaussians: <span id="count">Loading...</span></p>
        <p>File Size: <span id="size">Loading...</span></p>
    </div>
    <canvas id="canvas"></canvas>
    
    <script src="https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js"></script>
    <script src="threejs_integration.js"></script>
    <script>
        // Initialize Three.js scene
        const scene = new THREE.Scene();
        const camera = new THREE.PerspectiveCamera(75, window.innerWidth/window.innerHeight, 0.1, 1000);
        const renderer = new THREE.WebGLRenderer({{canvas: document.getElementById('canvas')}});
        
        renderer.setSize(window.innerWidth, window.innerHeight);
        renderer.setClearColor(0x000000);
        
        // Load gaussian splats
        const loader = new GaussianSplatsLoader(scene, camera, renderer);
        loader.loadCompressed('./models/compressed/').then(mesh => {{
            if (mesh) {{
                document.getElementById('count').textContent = mesh.geometry.attributes.position.count;
                camera.position.z = 5;
            }}
        }});
        
        // Animation loop
        function animate() {{
            requestAnimationFrame(animate);
            renderer.render(scene, camera);
        }}
        animate();
    </script>
</body>
</html>
        '''
        
        with open(examples_dir / "demo.html", 'w') as f:
            f.write(html_demo)
        
        print(f"   📝 Integration examples generated")
        return examples_dir
    
    def _estimate_render_fps(self, num_gaussians: int) -> str:
        """Estimate rendering FPS based on gaussian count"""
        if num_gaussians < 100000:
            return "60+ FPS (mobile: 30+)"
        elif num_gaussians < 500000:
            return "30-60 FPS (mobile: 15-30)"
        elif num_gaussians < 1000000:
            return "15-30 FPS (mobile: 10-15)"
        else:
            return "<15 FPS (mobile: <10)"
    
    def _estimate_runtime_memory(self, num_gaussians: int) -> int:
        """Estimate runtime memory usage in MB"""
        return int(num_gaussians / 1000000 * 200)  # ~200MB per 1M gaussians
    
    def _get_render_recommendations(self, num_gaussians: int) -> Dict[str, Any]:
        """Get rendering recommendations based on model size"""
        if num_gaussians < 250000:
            return {
                'target_devices': ['mobile', 'desktop'],
                'quality_settings': 'high',
                'streaming_needed': False,
                'fallback_needed': False
            }
        elif num_gaussians < 1000000:
            return {
                'target_devices': ['desktop', 'high_end_mobile'],
                'quality_settings': 'medium',
                'streaming_needed': True,
                'fallback_needed': False
            }
        else:
            return {
                'target_devices': ['desktop_only'],
                'quality_settings': 'adaptive',
                'streaming_needed': True,
                'fallback_needed': True
            }
    
    def _score_file_size(self, num_gaussians: int) -> float:
        """Score file size suitability for web (0-1)"""
        size_mb = num_gaussians / 1000000 * 16  # Estimated compressed size
        if size_mb < 10:
            return 1.0
        elif size_mb < 25:
            return 0.8
        elif size_mb < 50:
            return 0.6
        elif size_mb < 100:
            return 0.4
        else:
            return 0.2
    
    def _score_performance(self, num_gaussians: int) -> float:
        """Score expected web performance (0-1)"""
        if num_gaussians < 100000:
            return 1.0  # Excellent performance
        elif num_gaussians < 500000:
            return 0.8  # Good performance
        elif num_gaussians < 1000000:
            return 0.6  # Fair performance
        elif num_gaussians < 2000000:
            return 0.4  # Poor performance
        else:
            return 0.2  # Very poor performance
    
    def _score_quality(self, training_metrics: Dict[str, Any]) -> float:
        """Score quality based on training metrics (0-1)"""
        final_metrics = training_metrics.get('final_metrics', {})
        psnr = final_metrics.get('psnr', 25.0)
        
        # Score based on PSNR
        if psnr >= 30:
            return 1.0
        elif psnr >= 28:
            return 0.8
        elif psnr >= 26:
            return 0.6
        elif psnr >= 24:
            return 0.4
        else:
            return 0.2
    
    def _generate_recommendations(self, gaussians: Dict[str, torch.Tensor], 
                                training_metrics: Dict[str, Any]) -> List[str]:
        """Generate optimization recommendations"""
        recommendations = []
        num_gaussians = len(gaussians['means'])
        opacities = gaussians['opacities'].detach().cpu()
        
        # File size recommendations
        if num_gaussians > 1500000:
            recommendations.append("Consider MCMC strategy for better compression")
            recommendations.append("Enable aggressive pruning (opacity threshold > 0.01)")
        
        # Performance recommendations  
        if num_gaussians > 500000:
            recommendations.append("Enable streaming support for large models")
            recommendations.append("Set radius_clip > 0.5 for better web performance")
        
        # Quality recommendations
        low_opacity_count = (opacities < 0.01).sum().item()
        if low_opacity_count > num_gaussians * 0.1:
            recommendations.append("Increase pruning threshold to remove low-opacity gaussians")
        
        # Web-specific recommendations
        if num_gaussians < 100000:
            recommendations.append("Model is web-ready - excellent for all devices")
        elif num_gaussians < 500000:
            recommendations.append("Good for desktop web, consider mobile optimization")
        else:
            recommendations.append("Large model - implement progressive loading")
            recommendations.append("Consider creating mobile-optimized version")
        
        return recommendations


if __name__ == "__main__":
    # Demo the export pipeline
    print("📦 gsplat Web Export Pipeline Demo")
    
    # Create dummy data for demo
    dummy_gaussians = {
        'means': torch.randn(10000, 3),
        'scales': torch.rand(10000, 3) * 0.1,
        'quats': torch.rand(10000, 4),
        'opacities': torch.rand(10000),
        'sh0': torch.rand(10000, 3)
    }
    
    dummy_metrics = {
        'final_metrics': {'psnr': 28.5, 'ssim': 0.85},
        'training_time': 1200,
        'final_loss': 0.02
    }
    
    # Demo export
    output_path = Path("./demo_output")
    config = {
        'save_ply': True,
        'save_compressed': True,
        'save_streaming': False,
        'export_quality_report': True
    }
    
    pipeline = WebExportPipeline(output_path, config)
    exports = pipeline.export_all_formats(dummy_gaussians, dummy_metrics)
    
    print(f"✅ Demo exports created in: {output_path}")
    for export_type, path in exports.items():
        print(f"   {export_type}: {path}")
