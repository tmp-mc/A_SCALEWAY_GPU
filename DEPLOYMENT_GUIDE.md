# GitHub Deployment and Release Guide

This guide covers how to create a GitHub release for easy deployment and how to access private repositories on new virtual machines.

## 🚀 Creating a GitHub Release

### Step 1: Create a Release Archive

After pushing your code to GitHub, create a release package:

```bash
# Create a tar.gz file of the entire project
tar -czf deploy.tar.gz --exclude='.git' .

# Or create it without the deployment guide and other docs
tar -czf deploy.tar.gz vm-deployment/ README.md .gitignore
```

### Step 2: Create GitHub Release

1. **Go to your repository**: https://github.com/tmp-mc/A_SCRIPT_GPU
2. **Click "Releases"** on the right sidebar
3. **Click "Create a new release"**
4. **Tag version**: Use `v1.0.0` or similar
5. **Release title**: `3D Reconstruction Pipeline v1.0.0`
6. **Description**:
```markdown
# 3D Reconstruction Pipeline - Complete VM Deployment

## What's Included
- ✅ One-command Ubuntu 24.04 deployment
- ✅ CUDA 12.6 + RTX 4090 optimization
- ✅ COLMAP with CUDA acceleration
- ✅ Web-optimized Gaussian Splatting
- ✅ Interactive Bunny CDN setup
- ✅ Complete project structure

## Quick Install
```bash
curl -sSL https://github.com/tmp-mc/A_SCRIPT_GPU/releases/latest/download/deploy.tar.gz | tar -xz && cd A_SCRIPT_GPU && ./vm-deployment/deploy.sh
```

## System Requirements
- Ubuntu 24.04 LTS (fresh VM)
- 30+ GB disk space
- 8+ GB RAM (16+ recommended)
- NVIDIA GPU (optional but recommended)

## Documentation
See `vm-deployment/README.md` for complete configuration options and troubleshooting.

## Deployment Time
Approximately 30-60 minutes depending on internet speed and hardware.
```

7. **Upload the `deploy.tar.gz` file** by dragging it to the "Attach binaries" area
8. **Click "Publish release"**

### Step 3: Test the One-Liner

After creating the release, test the installation command:

```bash
curl -sSL https://github.com/tmp-mc/A_SCRIPT_GPU/releases/latest/download/deploy.tar.gz | tar -xz && cd A_SCRIPT_GPU && ./vm-deployment/deploy.sh
```

## 🔐 Accessing Private Repositories on New VMs

### Method 1: SSH Keys (Recommended)

#### Generate SSH Key on VM
```bash
# Generate new SSH key
ssh-keygen -t ed25519 -C "your-email@example.com"

# Start SSH agent and add key
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

# Display public key to copy
cat ~/.ssh/id_ed25519.pub
```

#### Add SSH Key to GitHub
1. **Copy the public key** from the output above
2. **Go to GitHub Settings**: https://github.com/settings/keys
3. **Click "New SSH key"**
4. **Title**: "VM-[hostname]" or similar
5. **Paste the public key**
6. **Click "Add SSH key"**

#### Test SSH Connection
```bash
# Test GitHub SSH connection
ssh -T git@github.com

# Should show: "Hi username! You've successfully authenticated"
```

#### Clone Repository
```bash
# Clone using SSH
git clone git@github.com:tmp-mc/A_SCRIPT_GPU.git
cd A_SCRIPT_GPU
./vm-deployment/deploy.sh
```

### Method 2: Personal Access Token (Alternative)

#### Create Personal Access Token
1. **Go to GitHub Settings**: https://github.com/settings/tokens
2. **Click "Generate new token (classic)"**
3. **Note**: "VM Access Token"
4. **Expiration**: Set as needed (30 days recommended)
5. **Scopes**: Select `repo` (full repository access)
6. **Click "Generate token"**
7. **Copy the token immediately** (you won't see it again)

#### Use Token for Cloning
```bash
# Clone using HTTPS with token
git clone https://USERNAME:TOKEN@github.com/tmp-mc/A_SCRIPT_GPU.git

# Example:
git clone https://tmp-mc:ghp_xxxxxxxxxxxxxxxxxxxx@github.com/tmp-mc/A_SCRIPT_GPU.git

cd A_SCRIPT_GPU
./vm-deployment/deploy.sh
```

#### Store Token Securely (Optional)
```bash
# Configure git to cache credentials
git config --global credential.helper store

# Or use credential manager (more secure)
git config --global credential.helper manager-core
```

### Method 3: GitHub CLI (Easiest for Repeated Use)

#### Install GitHub CLI
```bash
# Install on Ubuntu 24.04
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo apt install gh
```

#### Authenticate and Clone
```bash
# Login to GitHub (will open browser or show device code)
gh auth login

# Clone repository
gh repo clone tmp-mc/A_SCRIPT_GPU
cd A_SCRIPT_GPU
./vm-deployment/deploy.sh
```

## 📝 Deployment Workflow Summary

### For Public Access (Recommended)
```bash
# One-liner installation (no authentication needed)
curl -sSL https://github.com/tmp-mc/A_SCRIPT_GPU/releases/latest/download/deploy.tar.gz | tar -xz && cd A_SCRIPT_GPU && ./vm-deployment/deploy.sh
```

### For Development/Updates
```bash
# Using SSH (after setting up SSH key)
git clone git@github.com:tmp-mc/A_SCRIPT_GPU.git
cd A_SCRIPT_GPU
./vm-deployment/deploy.sh
```

### For Private Repository Access
```bash
# Method 1: SSH Key (most secure)
ssh-keygen -t ed25519 -C "vm@example.com"
cat ~/.ssh/id_ed25519.pub  # Add to GitHub SSH keys
git clone git@github.com:tmp-mc/A_SCRIPT_GPU.git

# Method 2: Personal Access Token
git clone https://username:token@github.com/tmp-mc/A_SCRIPT_GPU.git

# Method 3: GitHub CLI (easiest)
gh auth login
gh repo clone tmp-mc/A_SCRIPT_GPU
```

## 🔧 Updating the Deployment

### Push Updates
```bash
# Make changes to files
git add .
git commit -m "Update: description of changes"
git push origin main
```

### Create New Release
1. Create new tar.gz: `tar -czf deploy.tar.gz vm-deployment/ README.md .gitignore`
2. Go to GitHub releases
3. Create new release with updated version (e.g., v1.1.0)
4. Upload new tar.gz file
5. Publish release

The one-liner installation command will automatically use the latest release.

## 🚨 Security Notes

### SSH Keys
- Generate unique SSH keys for each VM
- Remove SSH keys from GitHub when VMs are destroyed
- Use `ssh-add -l` to verify loaded keys

### Personal Access Tokens
- Set short expiration periods (30 days max)
- Delete tokens when no longer needed
- Never share tokens or commit them to code
- Use fine-grained tokens when possible

### Best Practices
- Use SSH keys for long-term VM access
- Use personal access tokens for temporary/automated access
- Use GitHub CLI for interactive development
- Always use the GitHub releases method for production deployments

This approach provides multiple secure ways to access your private repository while keeping the main deployment process simple with the one-liner installation.
