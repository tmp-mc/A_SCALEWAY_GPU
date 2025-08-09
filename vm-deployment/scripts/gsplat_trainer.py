#!/usr/bin/env python3
"""
gsplat Gaussian Splatting Trainer - Web-Optimized Version
Advanced training with comprehensive parameter control and web integration
"""

import os
import sys
import torch
import numpy as np
from pathlib import Path
import argparse
import json
from typing import Dict, Tuple, Optional
import time

# Import our web-optimized modules
try:
    from web_presets import WebTrainingConfig, get_preset, print_parameter_help, PARAMETER_DOCS
    from export_pipeline import WebExportPipeline
except ImportError:
    print("❌ Web optimization modules not found. Ensure web_presets.py and export_pipeline.py are in the same directory.")
    sys.exit(1)

# gsplat imports
try:
    from gsplat import rasterization, DefaultStrategy, MCMCStrategy
    from gsplat.compression import PngCompression
except ImportError:
    print("❌ gsplat not installed. Run: pip install git+https://github.com/nerfstudio-project/gsplat.git")
    sys.exit(1)

# Utility imports
try:
    import imageio
    from tqdm import tqdm
except ImportError:
    print("❌ Required packages missing. Run: pip install imageio tqdm")
    sys.exit(1)


class ColmapDataLoader:
    """Simplified COLMAP data loader"""
    
    def __init__(self, colmap_path: Path):
        self.colmap_path = Path(colmap_path)
        self.images_path = self.colmap_path / "images"
        
        print(f"📁 Loading COLMAP data from: {self.colmap_path}")
        
        # Load COLMAP data
        self.cameras = self._load_cameras()
        self.images = self._load_images()
        self.points3d = self._load_points3d()
        
        print(f"📊 Loaded {len(self.cameras)} cameras, {len(self.images)} images, {len(self.points3d)} 3D points")
        
    def _load_cameras(self) -> Dict:
        """Load camera parameters from cameras.bin"""
        cameras_bin = self.colmap_path / "cameras.bin"
        if not cameras_bin.exists():
            raise FileNotFoundError(f"cameras.bin not found in {self.colmap_path}")
        
        cameras = {}
        with open(cameras_bin, 'rb') as f:
            num_cameras = int.from_bytes(f.read(8), 'little')
            
            for _ in range(num_cameras):
                camera_id = int.from_bytes(f.read(4), 'little')
                model_id = int.from_bytes(f.read(4), 'little')
                width = int.from_bytes(f.read(8), 'little')  
                height = int.from_bytes(f.read(8), 'little')
                
                # Read camera parameters
                params = []
                for _ in range(4):  # fx, fy, cx, cy
                    param_bytes = f.read(8)
                    param = np.frombuffer(param_bytes, dtype=np.float64)[0]
                    params.append(param)
                
                cameras[camera_id] = {
                    'id': camera_id,
                    'model': 'PINHOLE',
                    'width': width,
                    'height': height,
                    'params': params
                }
        
        return cameras
    
    def _load_images(self) -> Dict:
        """Load image poses from images.bin"""
        images_bin = self.colmap_path / "images.bin"
        if not images_bin.exists():
            raise FileNotFoundError(f"images.bin not found in {self.colmap_path}")
        
        images = {}
        with open(images_bin, 'rb') as f:
            num_images = int.from_bytes(f.read(8), 'little')
            
            for _ in range(num_images):
                image_id = int.from_bytes(f.read(4), 'little')
                
                # Read quaternion (w, x, y, z)
                quat = []
                for _ in range(4):
                    quat_bytes = f.read(8)
                    q = np.frombuffer(quat_bytes, dtype=np.float64)[0]
                    quat.append(q)
                
                # Read translation
                trans = []
                for _ in range(3):
                    trans_bytes = f.read(8)
                    t = np.frombuffer(trans_bytes, dtype=np.float64)[0]
                    trans.append(t)
                
                camera_id = int.from_bytes(f.read(4), 'little')
                
                # Read image name
                name_bytes = []
                while True:
                    byte = f.read(1)
                    if byte == b'\x00':
                        break
                    name_bytes.append(byte)
                name = b''.join(name_bytes).decode('utf-8')
                
                # Skip 2D points data
                num_points2d = int.from_bytes(f.read(8), 'little')
                f.read(num_points2d * 24)  # Skip point2d data
                
                images[image_id] = {
                    'id': image_id,
                    'quat': quat,
                    'trans': trans,
                    'camera_id': camera_id,
                    'name': name
                }
        
        return images
    
    def _load_points3d(self) -> Dict:
        """Load 3D points from points3D.bin"""
        points3d_bin = self.colmap_path / "points3D.bin"
        if not points3d_bin.exists():
            print("⚠️  points3D.bin not found - using random initialization")
            return {}
        
        points = {}
        with open(points3d_bin, 'rb') as f:
            num_points = int.from_bytes(f.read(8), 'little')
            
            for _ in range(num_points):
                point_id = int.from_bytes(f.read(8), 'little')
                
                # Read XYZ
                xyz = []
                for _ in range(3):
                    xyz_bytes = f.read(8)
                    coord = np.frombuffer(xyz_bytes, dtype=np.float64)[0]
                    xyz.append(coord)
                
                # Read RGB
                rgb = []
                for _ in range(3):
                    color_byte = f.read(1)
                    rgb.append(int.from_bytes(color_byte, 'little'))
                
                # Read error
                error_bytes = f.read(8)
                error = np.frombuffer(error_bytes, dtype=np.float64)[0]
                
                # Skip track data
                track_length = int.from_bytes(f.read(8), 'little')
                f.read(track_length * 8)
                
                points[point_id] = {
                    'xyz': xyz,
                    'rgb': [c/255.0 for c in rgb],
                    'error': error
                }
        
        return points
    
    def get_training_data(self, device: torch.device) -> Tuple[Dict[str, torch.Tensor], Dict]:
        """Convert COLMAP data to gsplat format"""
        
        # Initialize 3D gaussians
        if self.points3d:
            points = list(self.points3d.values())
            means = torch.tensor([p['xyz'] for p in points], device=device, dtype=torch.float32)
            colors = torch.tensor([p['rgb'] for p in points], device=device, dtype=torch.float32)
            num_gaussians = len(points)
            print(f"🎯 Initialized {num_gaussians} gaussians from COLMAP points")
        else:
            # Random initialization
            num_gaussians = 5000
            means = torch.randn(num_gaussians, 3, device=device) * 0.1
            colors = torch.rand(num_gaussians, 3, device=device)
            print(f"🎲 Random initialization with {num_gaussians} gaussians")
        
        # Initialize scales, rotations, opacities
        scales = torch.ones(num_gaussians, 3, device=device) * 0.01
        quats = torch.zeros(num_gaussians, 4, device=device)
        quats[:, 0] = 1.0  # w component
        opacities = torch.ones(num_gaussians, device=device) * 0.9
        
        # Convert to parameters
        gaussians = {
            'means': torch.nn.Parameter(means.requires_grad_(True)),
            'scales': torch.nn.Parameter(scales.requires_grad_(True)), 
            'quats': torch.nn.Parameter(quats.requires_grad_(True)),
            'opacities': torch.nn.Parameter(opacities.requires_grad_(True)),
            'sh0': torch.nn.Parameter(colors.requires_grad_(True)),
        }
        
        # Prepare camera data
        camera_data = {
            'cameras': self.cameras,
            'images': self.images,
            'images_path': self.images_path
        }
        
        return gaussians, camera_data


class GSplatTrainer:
    """Web-optimized gsplat trainer with comprehensive configuration"""
    
    def __init__(self, config: WebTrainingConfig):
        self.config = config
        self.device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
        
        print(f"🔧 Using device: {self.device}")
        
        # Show configuration estimates
        estimates = self.config.estimate_metrics()
        print(f"📊 Training estimates:")
        print(f"   Time: {estimates['estimated_training_time_minutes']}min")
        print(f"   File size: {estimates['estimated_file_size_mb']:.1f}MB")
        print(f"   Memory: {estimates['memory_usage_gb']:.1f}GB")
        print(f"   Performance: {estimates['web_performance']}")
        
        # Multi-GPU setup
        if self.config.distributed and torch.cuda.device_count() > 1:
            print(f"🔗 Multi-GPU training with {torch.cuda.device_count()} GPUs")
            self.config.distributed = True
        else:
            self.config.distributed = False
        
        # Initialize strategy based on configuration
        self.strategy = self._create_strategy()
        
        # Quality tracking
        self.best_psnr = 0.0
        self.quality_target_reached = False
        self.training_metrics = {
            'losses': [],
            'gaussian_counts': [],
            'psnr_history': [],
            'training_start_time': None
        }
    
    def _create_strategy(self):
        """Create training strategy based on configuration"""
        strategy_config = self.config.get_strategy_config()
        
        if strategy_config['type'] == 'mcmc':
            print(f"⚡ Using MCMC strategy (cap: {strategy_config['cap_max']:,})")
            return MCMCStrategy(
                cap_max=strategy_config['cap_max'],
                refine_start_iter=strategy_config.get('refine_start_iter', self.config.densify_start_iter),
                refine_stop_iter=strategy_config.get('refine_stop_iter', self.config.densify_stop_iter),
                min_opacity=strategy_config.get('min_opacity', self.config.prune_opacity),
                verbose=True
            )
        else:
            print(f"⚡ Using default strategy ({self.config.strategy})")
            return DefaultStrategy(
                prune_opa=strategy_config.get('prune_opa', self.config.prune_opacity),
                grow_grad2d=strategy_config.get('grow_grad2d', self.config.densify_grad_threshold),
                refine_start_iter=self.config.densify_start_iter,
                refine_stop_iter=strategy_config.get('refine_stop_iter', self.config.densify_stop_iter),
                reset_every=self.config.opacity_reset_interval,
                absgrad=strategy_config.get('absgrad', self.config.use_absgrad),
                verbose=True
            )
    
    def setup_optimizers(self, gaussians: Dict[str, torch.Tensor]) -> Dict:
        """Setup optimizers"""
        optimizers = {}
        
        for key, param in gaussians.items():
            if key == 'means':
                lr = self.config.lr_means
            elif key == 'scales':
                lr = self.config.lr_scales
            elif key == 'quats':
                lr = self.config.lr_quats
            elif key == 'opacities':
                lr = self.config.lr_opacities
            elif key == 'sh0':
                lr = self.config.lr_sh0
            else:
                lr = 0.001
            
            optimizers[key] = torch.optim.Adam([param], lr=lr)
        
        return optimizers
    
    def load_image(self, image_path: Path) -> torch.Tensor:
        """Load and preprocess image"""
        try:
            img = imageio.imread(image_path)
            img = img.astype(np.float32) / 255.0
            
            # Convert to tensor [H, W, C]
            img_tensor = torch.from_numpy(img).to(self.device)
            return img_tensor
        except Exception as e:
            print(f"❌ Error loading image {image_path}: {e}")
            return None
    
    def train(self, colmap_path: Path, output_path: Path):
        """Main training loop"""
        print(f"🚀 Starting gsplat training")
        print(f"   Iterations: {self.config.iterations:,}")
        print(f"   Features: AbsGrad={self.config.use_absgrad}, Antialiasing={self.config.use_antialiasing}")
        
        # Load data
        loader = ColmapDataLoader(colmap_path)
        gaussians, camera_data = loader.get_training_data(self.device)
        
        # Setup optimizers
        optimizers = self.setup_optimizers(gaussians)
        
        # Initialize strategy
        self.strategy.check_sanity(gaussians, optimizers)
        strategy_state = self.strategy.initialize_state()
        
        # Prepare output directory
        output_path = Path(output_path)
        output_path.mkdir(parents=True, exist_ok=True)
        checkpoints_dir = output_path / "checkpoints"
        checkpoints_dir.mkdir(exist_ok=True)
        
        # Training loop
        start_time = time.time()
        losses = []
        
        print("🎯 Starting training loop...")
        
        for iteration in tqdm(range(self.config.iterations), desc="Training"):
            
            # Sample random camera view
            image_ids = list(camera_data['images'].keys())
            img_id = np.random.choice(image_ids)
            image_info = camera_data['images'][img_id]
            camera_info = camera_data['cameras'][image_info['camera_id']]
            
            # Load ground truth image
            image_path = camera_data['images_path'] / image_info['name']
            gt_image = self.load_image(image_path)
            if gt_image is None:
                continue
            
            height, width = gt_image.shape[:2]
            
            # Prepare camera matrices
            fx, fy, cx, cy = camera_info['params']
            K = torch.tensor([[fx, 0, cx], [0, fy, cy], [0, 0, 1]], 
                           device=self.device, dtype=torch.float32).unsqueeze(0)
            
            # Convert COLMAP pose to view matrix (simplified)
            quat = torch.tensor(image_info['quat'], device=self.device, dtype=torch.float32)
            trans = torch.tensor(image_info['trans'], device=self.device, dtype=torch.float32)
            
            # Simplified rotation matrix conversion
            w, x, y, z = quat
            R = torch.tensor([
                [1-2*(y*y+z*z), 2*(x*y-w*z), 2*(x*z+w*y)],
                [2*(x*y+w*z), 1-2*(x*x+z*z), 2*(y*z-w*x)],
                [2*(x*z-w*y), 2*(y*z+w*x), 1-2*(x*x+y*y)]
            ], device=self.device, dtype=torch.float32)
            
            viewmat = torch.eye(4, device=self.device, dtype=torch.float32)
            viewmat[:3, :3] = R.T
            viewmat[:3, 3] = -R.T @ trans
            viewmat = viewmat.unsqueeze(0)
            
            # Pre-backward step
            self.strategy.step_pre_backward(
                gaussians, optimizers, strategy_state, iteration, {}
            )
            
            # Rasterization
            try:
                colors, alphas, info = rasterization(
                    means=gaussians['means'],
                    quats=gaussians['quats'], 
                    scales=gaussians['scales'],
                    opacities=gaussians['opacities'],
                    colors=gaussians['sh0'],
                    viewmats=viewmat,
                    Ks=K,
                    width=width,
                    height=height,
                    rasterize_mode='antialiased' if self.config.use_antialiasing else 'classic',
                    distributed=self.config.distributed,
                    absgrad=self.config.use_absgrad
                )
                
                rendered = colors.squeeze(0)
                
                # Compute loss (L1)
                loss = torch.abs(rendered - gt_image).mean()
                
                # Backward pass
                loss.backward()
                
                # Post-backward step
                self.strategy.step_post_backward(
                    gaussians, optimizers, strategy_state, iteration, info
                )
                
                # Update optimizers
                for opt in optimizers.values():
                    opt.step()
                    opt.zero_grad()
                
                losses.append(loss.item())
                
                # Logging
                if iteration % 100 == 0:
                    avg_loss = np.mean(losses[-100:]) if losses else loss.item()
                    gaussian_count = len(gaussians['means'])
                    tqdm.write(f"Iter {iteration:>6}: Loss={avg_loss:.6f}, Gaussians={gaussian_count:,}")
                
                # Save checkpoints
                if iteration > 0 and iteration % self.config.save_interval == 0:
                    checkpoint_path = checkpoints_dir / f"checkpoint_{iteration:06d}.pt"
                    self.save_checkpoint(gaussians, checkpoint_path)
                    print(f"💾 Checkpoint saved: {checkpoint_path.name}")
                    
            except Exception as e:
                print(f"❌ Error in iteration {iteration}: {e}")
                continue
        
        # Final save
        print("✅ Training completed! Saving final results...")
        
        # Save final model
        final_checkpoint = output_path / "final_model.pt" 
        self.save_checkpoint(gaussians, final_checkpoint)
        
        # Save PLY format
        if self.config.save_ply:
            ply_path = output_path / "point_cloud.ply"
            self.save_ply(gaussians, ply_path)
            print(f"💾 PLY saved: {ply_path}")
        
        # Compress output
        if self.config.compress_output:
            try:
                compressed_dir = output_path / "compressed"
                compressed_dir.mkdir(exist_ok=True)
                compressor = PngCompression(verbose=True)
                compressor.compress(str(compressed_dir), gaussians)
                print(f"📦 Compressed model saved: {compressed_dir}")
            except Exception as e:
                print(f"⚠️  Compression failed: {e}")
        
        training_time = time.time() - start_time
        hours = int(training_time // 3600)
        minutes = int((training_time % 3600) // 60)
        seconds = int(training_time % 60)
        
        print(f"⏱️  Training completed in {hours}h {minutes}m {seconds}s")
        print(f"📊 Final model: {len(gaussians['means']):,} gaussians")
        
        if losses:
            final_loss = np.mean(losses[-100:])
            print(f"📈 Final loss: {final_loss:.6f}")
    
    def train_with_web_export(self, colmap_path: Path, output_path: Path):
        """Enhanced training with web export pipeline"""
        print(f"🚀 Starting web-optimized gsplat training")
        print(f"   Strategy: {self.config.strategy}")
        print(f"   Target: {self.config.target_file_size_mb:.1f}MB @ {self.config.quality_target_psnr:.1f}dB PSNR")
        
        # Record training start
        self.training_metrics['training_start_time'] = time.time()
        
        # Load data
        loader = ColmapDataLoader(colmap_path)
        gaussians, camera_data = loader.get_training_data(self.device)
        
        # Limit initial gaussians based on capacity
        if len(gaussians['means']) > self.config.gaussian_capacity:
            print(f"🔪 Limiting initial gaussians from {len(gaussians['means']):,} to {self.config.gaussian_capacity:,}")
            for key in gaussians:
                gaussians[key] = torch.nn.Parameter(gaussians[key][:self.config.gaussian_capacity])
        
        # Setup optimizers
        optimizers = self.setup_optimizers(gaussians)
        
        # Initialize strategy
        self.strategy.check_sanity(gaussians, optimizers)
        strategy_state = self.strategy.initialize_state(scene_scale=1.0)
        
        # Prepare output directory
        output_path = Path(output_path)
        output_path.mkdir(parents=True, exist_ok=True)
        checkpoints_dir = output_path / "checkpoints"
        checkpoints_dir.mkdir(exist_ok=True)
        
        # Training loop with early stopping
        start_time = time.time()
        losses = []
        psnr_history = []
        
        print("🎯 Starting enhanced training loop...")
        
        for iteration in tqdm(range(self.config.iterations), desc="Training"):
            
            # Sample random camera view
            image_ids = list(camera_data['images'].keys())
            img_id = np.random.choice(image_ids)
            image_info = camera_data['images'][img_id]
            camera_info = camera_data['cameras'][image_info['camera_id']]
            
            # Load ground truth image
            image_path = camera_data['images_path'] / image_info['name']
            gt_image = self.load_image(image_path)
            if gt_image is None:
                continue
            
            height, width = gt_image.shape[:2]
            
            # Prepare camera matrices
            fx, fy, cx, cy = camera_info['params']
            K = torch.tensor([[fx, 0, cx], [0, fy, cy], [0, 0, 1]], 
                           device=self.device, dtype=torch.float32).unsqueeze(0)
            
            # Convert COLMAP pose to view matrix (simplified)
            quat = torch.tensor(image_info['quat'], device=self.device, dtype=torch.float32)
            trans = torch.tensor(image_info['trans'], device=self.device, dtype=torch.float32)
            
            # Simplified rotation matrix conversion
            w, x, y, z = quat
            R = torch.tensor([
                [1-2*(y*y+z*z), 2*(x*y-w*z), 2*(x*z+w*y)],
                [2*(x*y+w*z), 1-2*(x*x+z*z), 2*(y*z-w*x)],
                [2*(x*z-w*y), 2*(y*z+w*x), 1-2*(x*x+y*y)]
            ], device=self.device, dtype=torch.float32)
            
            viewmat = torch.eye(4, device=self.device, dtype=torch.float32)
            viewmat[:3, :3] = R.T
            viewmat[:3, 3] = -R.T @ trans
            viewmat = viewmat.unsqueeze(0)
            
            # Pre-backward step
            self.strategy.step_pre_backward(
                gaussians, optimizers, strategy_state, iteration, {}
            )
            
            # Rasterization with web optimizations
            try:
                colors, alphas, info = rasterization(
                    means=gaussians['means'],
                    quats=gaussians['quats'], 
                    scales=gaussians['scales'],
                    opacities=gaussians['opacities'],
                    colors=gaussians['sh0'],
                    viewmats=viewmat,
                    Ks=K,
                    width=width,
                    height=height,
                    rasterize_mode=self.config.render_mode,
                    distributed=self.config.distributed,
                    absgrad=self.config.use_absgrad,
                    radius_clip=self.config.radius_clip,
                    sparse_grad=self.config.sparse_grad
                )
                
                rendered = colors.squeeze(0)
                
                # Compute loss (L1)
                loss = torch.abs(rendered - gt_image).mean()
                
                # Backward pass
                loss.backward()
                
                # Post-backward step
                self.strategy.step_post_backward(
                    gaussians, optimizers, strategy_state, iteration, info
                )
                
                # Update optimizers
                for opt in optimizers.values():
                    opt.step()
                    opt.zero_grad()
                
                losses.append(loss.item())
                self.training_metrics['losses'].append(loss.item())
                self.training_metrics['gaussian_counts'].append(len(gaussians['means']))
                
                # Quality evaluation (simplified PSNR estimation)
                if iteration % self.config.eval_interval == 0:
                    mse = torch.mean((rendered - gt_image) ** 2)
                    psnr = -10 * torch.log10(mse + 1e-8)
                    psnr_history.append(psnr.item())
                    self.training_metrics['psnr_history'].append(psnr.item())
                    
                    if psnr.item() > self.best_psnr:
                        self.best_psnr = psnr.item()
                    
                    # Early stopping if quality target reached
                    if psnr.item() >= self.config.quality_target_psnr:
                        if not self.quality_target_reached:
                            print(f"🎯 Quality target reached! PSNR: {psnr.item():.2f}dB >= {self.config.quality_target_psnr:.2f}dB")
                            self.quality_target_reached = True
                            if iteration > self.config.iterations * 0.5:  # At least 50% complete
                                print(f"🚀 Early stopping at iteration {iteration}")
                                break
                
                # Enhanced logging
                if iteration % 100 == 0:
                    avg_loss = np.mean(losses[-100:]) if losses else loss.item()
                    gaussian_count = len(gaussians['means'])
                    current_psnr = psnr_history[-1] if psnr_history else 0
                    tqdm.write(f"Iter {iteration:>6}: Loss={avg_loss:.6f}, PSNR={current_psnr:.2f}dB, Gaussians={gaussian_count:,}")
                
                # Save checkpoints
                if iteration > 0 and iteration % self.config.save_interval == 0:
                    checkpoint_path = checkpoints_dir / f"checkpoint_{iteration:06d}.pt"
                    self.save_checkpoint(gaussians, checkpoint_path)
                    print(f"💾 Checkpoint saved: {checkpoint_path.name}")
                    
            except Exception as e:
                print(f"❌ Error in iteration {iteration}: {e}")
                continue
        
        # Finalize training metrics
        training_time = time.time() - start_time
        self.training_metrics.update({
            'final_loss': np.mean(losses[-100:]) if losses else 0,
            'best_psnr': self.best_psnr,
            'final_gaussian_count': len(gaussians['means']),
            'training_time_seconds': training_time,
            'quality_target_reached': self.quality_target_reached,
            'iterations_completed': iteration + 1
        })
        
        print("✅ Training completed! Starting web export pipeline...")
        
        # Initialize web export pipeline
        export_config = {
            'save_ply': self.config.save_ply,
            'save_compressed': self.config.save_compressed,
            'save_streaming': self.config.save_streaming,
            'export_quality_report': self.config.export_quality_report
        }
        
        export_pipeline = WebExportPipeline(output_path, export_config)
        
        # Export all formats
        exports = export_pipeline.export_all_formats(gaussians, {
            'final_metrics': {
                'psnr': self.best_psnr,
                'loss': self.training_metrics['final_loss']
            },
            'training_time': training_time,
            'iterations_completed': self.training_metrics['iterations_completed'],
            'config': self.config.__dict__
        })
        
        # Final summary
        hours = int(training_time // 3600)
        minutes = int((training_time % 3600) // 60)
        seconds = int(training_time % 60)
        
        print(f"\n🎉 Web-optimized training completed!")
        print(f"⏱️  Training time: {hours}h {minutes}m {seconds}s")
        print(f"📊 Final model: {len(gaussians['means']):,} gaussians")
        print(f"🎨 Best PSNR: {self.best_psnr:.2f}dB")
        print(f"📁 Exports created:")
        for export_type, path in exports.items():
            print(f"   {export_type}: {path.name if hasattr(path, 'name') else path}")
        
        return exports
    
    def save_checkpoint(self, gaussians: Dict[str, torch.Tensor], path: Path):
        """Save training checkpoint"""
        checkpoint = {
            'gaussians': {k: v.detach().cpu() for k, v in gaussians.items()},
            'config': self.config.__dict__,
            'timestamp': time.time()
        }
        torch.save(checkpoint, path)
    
    def save_ply(self, gaussians: Dict[str, torch.Tensor], path: Path):
        """Save gaussians in PLY format"""
        means = gaussians['means'].detach().cpu().numpy()
        colors = gaussians['sh0'].detach().cpu().numpy()
        
        # Convert colors to 0-255 range
        colors = np.clip(colors * 255, 0, 255).astype(np.uint8)
        
        with open(path, 'w') as f:
            f.write("ply\n")
            f.write("format ascii 1.0\n")
            f.write(f"element vertex {len(means)}\n")
            f.write("property float x\n")
            f.write("property float y\n") 
            f.write("property float z\n")
            f.write("property uchar red\n")
            f.write("property uchar green\n")
            f.write("property uchar blue\n")
            f.write("end_header\n")
            
            for i in range(len(means)):
                x, y, z = means[i]
                r, g, b = colors[i]
                f.write(f"{x} {y} {z} {r} {g} {b}\n")


def main():
    parser = argparse.ArgumentParser(
        description="gsplat Web-Optimized Gaussian Splatting Training",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Web Presets:
  mobile     - Ultra-compressed for mobile web (8MB, 12K iterations)
  desktop    - Balanced for desktop web (35MB, 20K iterations)
  premium    - High quality for premium web (80MB, 30K iterations)
  custom     - Full parameter control

Examples:
  python gsplat_trainer.py --preset mobile --colmap_path data/scene --output_path results/
  python gsplat_trainer.py --preset custom --help_param gaussian_capacity
        """
    )
    
    parser.add_argument('--colmap_path', type=str, required=True,
                      help='Path to COLMAP reconstruction (sparse/0)')
    parser.add_argument('--output_path', type=str, required=True,
                      help='Output directory for trained model')
    
    # Web preset system
    parser.add_argument('--preset', type=str, default='desktop',
                      choices=['mobile', 'desktop', 'premium', 'custom'],
                      help='Web-optimized training preset')
    
    # Parameter help system
    parser.add_argument('--help_param', type=str,
                      help='Show detailed help for a specific parameter')
    parser.add_argument('--list_params', action='store_true',
                      help='List all available parameters')
    
    # Custom parameter overrides
    parser.add_argument('--iterations', type=int,
                      help='Override iterations from preset')
    parser.add_argument('--gaussian_capacity', type=int,
                      help='Override gaussian capacity from preset')
    parser.add_argument('--target_file_size_mb', type=float,
                      help='Override target file size from preset')
    parser.add_argument('--quality_target_psnr', type=float,
                      help='Override quality target from preset')
    parser.add_argument('--strategy', type=str,
                      choices=['adaptive', 'mcmc', 'default', 'compression_focused'],
                      help='Override training strategy from preset')
    
    args = parser.parse_args()
    
    # Handle parameter help
    if args.help_param:
        print_parameter_help(args.help_param)
        return
    
    if args.list_params:
        print_parameter_help()
        return
    
    # Load web preset
    print("🎯 gsplat Web-Optimized Training")
    print("=" * 50)
    
    config = get_preset(args.preset)
    
    # Apply custom overrides
    if args.iterations:
        config.iterations = args.iterations
        print(f"   Override: iterations = {args.iterations:,}")
    
    if args.gaussian_capacity:
        config.gaussian_capacity = args.gaussian_capacity
        print(f"   Override: gaussian_capacity = {args.gaussian_capacity:,}")
    
    if args.target_file_size_mb:
        config.target_file_size_mb = args.target_file_size_mb
        print(f"   Override: target_file_size_mb = {args.target_file_size_mb:.1f}MB")
    
    if args.quality_target_psnr:
        config.quality_target_psnr = args.quality_target_psnr
        print(f"   Override: quality_target_psnr = {args.quality_target_psnr:.1f}dB")
    
    if args.strategy:
        config.strategy = args.strategy
        print(f"   Override: strategy = {args.strategy}")
    
    print("\n🔧 Final Configuration:")
    print(f"   Strategy: {config.strategy}")
    print(f"   Iterations: {config.iterations:,}")
    print(f"   Gaussian Capacity: {config.gaussian_capacity:,}")
    print(f"   Target File Size: {config.target_file_size_mb:.1f}MB")
    print(f"   Quality Target: {config.quality_target_psnr:.1f}dB")
    print(f"   AbsGrad: {config.use_absgrad}")
    print(f"   Anti-aliasing: {config.use_antialiasing}")
    print(f"   Multi-GPU: {config.distributed}")
    
    # Initialize trainer
    trainer = GSplatTrainer(config)
    
    # Enhanced training with web export
    trainer.train_with_web_export(Path(args.colmap_path), Path(args.output_path))


if __name__ == "__main__":
    main()
