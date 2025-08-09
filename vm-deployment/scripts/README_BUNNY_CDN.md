# Bunny CDN Integration Guide

Complete integration of Bunny CDN storage with the 3D reconstruction pipeline for secure image download and result upload.

## 🔐 Security-First Design

The API key is **never stored in files** for maximum security:

### API Key Options (in priority order):
1. **Interactive Prompt** (Most Secure) - Script prompts for key when needed
2. **Environment Variable** - `export BUNNY_API_KEY="your-key-here"`
3. **Command Line** - `--api-key` argument (not recommended for production)

## 📁 CDN Directory Structure

Your Bunny CDN storage zone should be organized as:

```
colmap/ (your storage zone)
├── inputs/           # Source images for reconstruction
│   ├── image001.jpg
│   ├── image002.jpg
│   ├── image003.png
│   └── ...
└── output/           # Generated results (auto-created)
    └── run_20250109_152322/
        ├── colmap/           # COLMAP sparse reconstruction
        │   └── sparse/
        ├── gaussian/         # Gaussian splatting models
        │   ├── final_model.pt
        │   ├── point_cloud.ply
        │   ├── compressed/   # Web-ready files
        │   └── streaming/    # Progressive loading
        ├── web_config/       # Web integration
        │   └── examples/     # Three.js code
        └── summary.txt       # Reconstruction report
```

## ⚙️ Configuration

Edit `vm-deployment/.env`:

```bash
# Bunny CDN Settings
BUNNY_STORAGE_ZONE=colmap
BUNNY_INPUT_PATH=inputs
BUNNY_OUTPUT_PATH=output

# Transfer Settings
MAX_DOWNLOAD_WORKERS=4
MAX_UPLOAD_WORKERS=2
ENABLE_AUTO_UPLOAD=true
```

## 🚀 Usage Examples

### Test Connection
```bash
cd ~/3d-reconstruction/scripts
python3 bunny_cdn.py test --storage-zone colmap
# Will prompt for API key securely
```

### Download Images
```bash
# Download all images from inputs/ folder
python3 bunny_cdn.py download \
    --storage-zone colmap \
    --remote-path inputs \
    --local-path ~/3d-reconstruction/data/images

# Download specific formats only
python3 bunny_cdn.py download \
    --storage-zone colmap \
    --remote-path inputs \
    --local-path ~/3d-reconstruction/data/images \
    --extensions .jpg .png
```

### Upload Results
```bash
# Upload reconstruction results
python3 bunny_cdn.py upload \
    --storage-zone colmap \
    --local-path ~/3d-reconstruction/output/results/latest \
    --remote-path output/run_$(date +%Y%m%d_%H%M%S)
```

### Environment Variable Method
```bash
# Set API key in environment (session only)
export BUNNY_API_KEY="a26a3ab5-e852-41f0-b9bc8b3a4fe7-eeed-4290"

# Now scripts won't prompt for key
python3 bunny_cdn.py test --storage-zone colmap
```

## 🔄 Pipeline Integration

The main reconstruction script automatically handles CDN operations:

```bash
# Auto-detect CDN usage and download images
./run-reconstruction.sh

# Force CDN download
./run-reconstruction.sh --cdn-only

# Use local images only
./run-reconstruction.sh --local-only

# Skip upload after reconstruction
./run-reconstruction.sh --no-upload
```

## 📊 Progress Tracking

The script provides detailed progress information:

```
📥 Bunny CDN Download
==============================
🔗 Bunny CDN Client initialized
   Storage Zone: colmap
   Hostname: storage.bunnycdn.com:21
✅ Connection successful! Found 3 items in root directory
📥 Downloading from inputs to /home/user/3d-reconstruction/data/images
📋 Found 25 files to download
Downloading: 100%|████████████| 25/25 [00:45<00:00,  1.81s/file] ✅: 25 ❌: 0
📥 Download complete: 25 successful, 0 failed
✅ Successfully downloaded 25 files to /home/user/3d-reconstruction/data/images
```

## 🛠️ Advanced Features

### Parallel Transfers
- **Downloads**: 4 parallel connections (configurable)
- **Uploads**: 2 parallel connections (bandwidth-friendly)
- **Connection Pooling**: Reuses FTP connections for efficiency

### Error Handling
- **Automatic Retry**: Failed transfers are retried
- **Connection Recovery**: Handles network interruptions
- **Partial Download Protection**: Validates file sizes
- **Graceful Degradation**: Continues on individual file failures

### File Validation
- **Extension Filtering**: Only downloads specified image formats
- **Size Verification**: Ensures complete transfers
- **Directory Creation**: Auto-creates local directories

## 🔧 Troubleshooting

### Connection Issues
```bash
# Test basic connectivity
python3 bunny_cdn.py test --storage-zone colmap

# Check FTP settings
telnet storage.bunnycdn.com 21
```

### API Key Problems
```bash
# Verify API key format (should be UUID-like)
echo $BUNNY_API_KEY | grep -E '^[a-f0-9-]{36}$'

# Clear cached credentials
unset BUNNY_API_KEY
```

### Transfer Failures
```bash
# Increase verbosity for debugging
python3 bunny_cdn.py download --storage-zone colmap --remote-path inputs --local-path ./test --max-workers 1

# Check disk space
df -h ~/3d-reconstruction/

# Verify remote directory exists
python3 bunny_cdn.py test --storage-zone colmap
```

### Permission Issues
```bash
# Ensure script is executable
chmod +x ~/3d-reconstruction/scripts/bunny_cdn.py

# Check local directory permissions
ls -la ~/3d-reconstruction/data/
```

## 📈 Performance Tips

### Optimal Settings
- **Download Workers**: 4 for most connections
- **Upload Workers**: 2 to avoid bandwidth saturation
- **File Organization**: Group similar files in CDN directories

### Large File Handling
- **Compression**: Results are automatically compressed for web
- **Streaming**: Large models support progressive loading
- **Chunking**: Files are transferred in optimal chunks

### Network Optimization
- **Passive FTP**: Automatically enabled for firewall compatibility
- **Connection Reuse**: Minimizes connection overhead
- **Timeout Handling**: Robust network error recovery

## 🌐 Web Integration

Uploaded results include web-ready formats:

### Compressed Models
- **PNG Compression**: ~90% size reduction
- **Quality Preservation**: Minimal visual loss
- **Fast Loading**: Optimized for web browsers

### Progressive Loading
- **Streaming Chunks**: Load models progressively
- **Importance Sorting**: Most visible gaussians first
- **Adaptive Quality**: Adjusts to device capabilities

### Integration Examples
- **Three.js Code**: Ready-to-use JavaScript examples
- **WebGL Shaders**: Optimized rendering shaders
- **HTML Demo**: Complete web viewer example

## 🔒 Security Best Practices

### API Key Management
- **Never commit** API keys to version control
- **Use environment variables** for automation
- **Rotate keys regularly** in production
- **Limit permissions** to specific storage zones

### Network Security
- **FTPS Support**: Encrypted transfers when available
- **Connection Validation**: Verifies server certificates
- **Timeout Protection**: Prevents hanging connections
- **Error Sanitization**: No sensitive data in logs

### Access Control
- **Zone Isolation**: Each project uses separate storage zones
- **Read-Only Keys**: Use separate keys for download-only operations
- **Audit Logging**: Track all CDN operations
- **IP Restrictions**: Configure CDN IP allowlists when possible

## 📚 Integration with Python Scripts

The CDN client integrates seamlessly with existing Python scripts:

### gsplat_trainer.py
- Automatically detects CDN configuration
- Downloads training images before processing
- Uploads trained models after completion

### export_pipeline.py
- Creates web-optimized formats
- Generates CDN-ready directory structure
- Includes integration examples

### web_presets.py
- Configures optimal settings for web deployment
- Balances quality vs file size for CDN delivery
- Provides mobile/desktop/premium presets

## 🎯 Complete Workflow

1. **Upload Images**: Place source images in CDN `inputs/` folder
2. **Run Pipeline**: `./run-reconstruction.sh` (auto-downloads images)
3. **Processing**: COLMAP → gsplat → web export
4. **Auto-Upload**: Results uploaded to CDN `output/` folder
5. **Web Access**: Results available via CDN URL

The entire process is automated with secure API key handling and comprehensive error recovery.
