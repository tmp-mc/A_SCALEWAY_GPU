# COLMAP Configuration Updates for Same Camera Sequential Images

## Summary of Changes Made

Based on your requirements for images taken with the same camera (just autofocus variations) in sequential order, the following optimal configurations have been implemented:

## ✅ Changes Applied

### 1. Camera Model: RADIAL → OPENCV
**File**: `vm-deployment/setup-env.sh`
```bash
# Old: COLMAP_CAMERA_MODEL=RADIAL
# New: COLMAP_CAMERA_MODEL=OPENCV
```

**Why**: OPENCV model handles lens distortion better than RADIAL, even for the same camera. With autofocus changes, subtle distortion variations can occur, and OPENCV provides more robust parameter estimation when sharing intrinsics across all images.

### 2. Matcher Type: exhaustive → sequential
**File**: `vm-deployment/setup-env.sh`
```bash
# Old: COLMAP_MATCHER_TYPE=exhaustive
# New: COLMAP_MATCHER_TYPE=sequential
```

**Why**: Perfect for sequential image capture (walking around object, video frames, etc.). Much faster than exhaustive matching while maintaining high quality for ordered image sets.

### 3. Vocabulary Tree Integration
**Files**: `vm-deployment/run-reconstruction.sh`
- Added automatic download of `vocab_tree_flickr100K_words1M.bin` (largest available ~600MB)
- Integrated vocabulary tree path into sequential matcher
- Added robust error handling and download verification

**Sequential Matching Parameters**:
```bash
--SequentialMatching.overlap 10
--SequentialMatching.loop_detection 1
--SequentialMatching.loop_detection_period 10
--SequentialMatching.loop_detection_num_images 50
--SequentialMatching.vocab_tree_path "$CACHE_DIR/vocab_tree_flickr100K_words1M.bin"
```

### 4. Multi-View Stereo: Kept DISABLED
**Setting**: `ENABLE_DENSE_RECONSTRUCTION=false` (default)

**Why**: Dense reconstruction doesn't improve gsplat results and actually can hurt performance by adding noise. Sparse reconstruction provides higher quality, more reliable points for Gaussian Splatting.

### 5. Default Values Updated
**File**: `vm-deployment/run-reconstruction.sh`
- Updated default fallbacks from RADIAL to OPENCV
- Updated default fallbacks from exhaustive to sequential
- Updated summary generation to reflect new defaults

## 📋 Current Optimal Configuration

```bash
# COLMAP Configuration
COLMAP_FEATURE_TYPE=sift
COLMAP_MATCHER_TYPE=sequential          # ✓ Changed
COLMAP_CAMERA_MODEL=OPENCV              # ✓ Changed

# Vocabulary tree automatically downloaded: 
# vocab_tree_flickr100K_words1M.bin (~600MB)

# Multi-View Stereo
ENABLE_DENSE_RECONSTRUCTION=false       # ✓ Optimal for gsplat
```

## 🔄 Pipeline Flow

1. **Feature Extraction**: SIFT features with OPENCV camera model
2. **Vocabulary Tree Download**: Automatic download of largest tree if needed
3. **Sequential Matching**: With vocabulary tree loop detection
4. **Sparse Reconstruction**: High-quality sparse point cloud
5. **Gaussian Splatting**: Optimal input from sparse reconstruction

## 🚀 Benefits of These Changes

### Performance Improvements:
- **Sequential matching**: 10-100x faster than exhaustive for large datasets
- **Loop detection**: Robust handling of revisited scenes/angles
- **No dense reconstruction**: Faster pipeline, less disk space

### Quality Improvements:
- **OPENCV camera model**: Better distortion handling for real cameras
- **Shared intrinsics**: More robust parameter estimation across all images
- **Large vocabulary tree**: Better loop closure detection
- **Sparse points only**: Cleaner input for gsplat optimization

### Robustness:
- **Automatic vocab tree download**: No manual setup required
- **Graceful degradation**: Pipeline continues even if vocab tree fails
- **Error handling**: Comprehensive validation and recovery

## 📝 Usage

The pipeline now works optimally for your use case:

1. **Setup** (one time):
   ```bash
   cd vm-deployment
   ./setup-system.sh
   ./build-deps.sh
   ./setup-env.sh
   ```

2. **Configure** (edit ~/.env file with your CDN settings)

3. **Run**:
   ```bash
   source ~/3d-reconstruction/activate.sh
   ./run-reconstruction.sh
   ```

## 🎯 Expected Results

- **Faster processing**: Sequential matching is much faster for ordered images
- **Better reconstruction**: OPENCV model provides more accurate camera parameters
- **Optimal gsplat input**: Clean sparse reconstruction without dense noise
- **Robust loop detection**: Large vocabulary tree improves scene understanding

## 📊 Configuration Summary

| Setting | Old Value | New Value | Reason |
|---------|-----------|-----------|---------|
| Camera Model | RADIAL | OPENCV | Better distortion handling |
| Matcher Type | exhaustive | sequential | Faster, optimized for ordered images |
| Vocabulary Tree | None | Largest (1M words) | Better loop detection |
| Dense Reconstruction | false | false | Optimal for gsplat |

All changes are backward compatible and will improve both speed and quality for your specific use case of sequential images from the same camera.
