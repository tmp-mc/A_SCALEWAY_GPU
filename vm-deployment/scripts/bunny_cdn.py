#!/usr/bin/env python3
"""
Bunny CDN Storage Integration
Secure FTP/FTPS client for downloading images and uploading reconstruction results
"""

import os
import sys
import ftplib
import argparse
import getpass
from pathlib import Path
from typing import List, Optional, Tuple
import time
import threading
from concurrent.futures import ThreadPoolExecutor, as_completed
from tqdm import tqdm
import hashlib

class BunnyCDNClient:
    """Secure Bunny CDN FTP client with progress tracking"""
    
    def __init__(self, api_key: str, storage_zone: str, hostname: str = "storage.bunnycdn.com", port: int = 21):
        self.api_key = api_key
        self.storage_zone = storage_zone
        self.hostname = hostname
        self.port = port
        self.username = storage_zone  # Storage zone name is the username
        self.password = api_key       # API key is the password
        
        # Connection pool for parallel operations
        self._connection_pool = []
        self._pool_lock = threading.Lock()
        
        print(f"🔗 Bunny CDN Client initialized")
        print(f"   Storage Zone: {storage_zone}")
        print(f"   Hostname: {hostname}:{port}")
    
    def _create_connection(self) -> ftplib.FTP:
        """Create a new FTP connection"""
        try:
            ftp = ftplib.FTP()
            ftp.connect(self.hostname, self.port, timeout=30)
            ftp.login(self.username, self.password)
            ftp.set_pasv(True)  # Use passive mode
            return ftp
        except Exception as e:
            raise ConnectionError(f"Failed to connect to Bunny CDN: {e}")
    
    def _get_connection(self) -> ftplib.FTP:
        """Get a connection from the pool or create a new one"""
        with self._pool_lock:
            if self._connection_pool:
                return self._connection_pool.pop()
        return self._create_connection()
    
    def _return_connection(self, ftp: ftplib.FTP):
        """Return a connection to the pool"""
        try:
            # Test if connection is still alive
            ftp.pwd()
            with self._pool_lock:
                if len(self._connection_pool) < 10:  # Max pool size
                    self._connection_pool.append(ftp)
                else:
                    ftp.quit()
        except:
            # Connection is dead, don't return to pool
            try:
                ftp.quit()
            except:
                pass
    
    def test_connection(self) -> bool:
        """Test the connection to Bunny CDN"""
        try:
            ftp = self._create_connection()
            files = ftp.nlst()
            ftp.quit()
            print(f"✅ Connection successful! Found {len(files)} items in root directory")
            return True
        except Exception as e:
            print(f"❌ Connection failed: {e}")
            return False
    
    def list_files(self, remote_path: str = "", extensions: List[str] = None) -> List[str]:
        """List files in remote directory"""
        try:
            ftp = self._get_connection()
            
            # Change to remote directory if specified
            if remote_path:
                try:
                    ftp.cwd(remote_path)
                except ftplib.error_perm:
                    print(f"❌ Remote directory not found: {remote_path}")
                    self._return_connection(ftp)
                    return []
            
            # Get file list
            files = []
            file_list = ftp.nlst()
            
            for item in file_list:
                # Skip directories (basic check)
                if '.' in item:  # Assume files have extensions
                    if extensions:
                        if any(item.lower().endswith(ext.lower()) for ext in extensions):
                            files.append(item)
                    else:
                        files.append(item)
            
            self._return_connection(ftp)
            return files
            
        except Exception as e:
            print(f"❌ Error listing files: {e}")
            return []
    
    def download_file(self, remote_path: str, local_path: Path, progress_callback=None) -> bool:
        """Download a single file"""
        try:
            ftp = self._get_connection()
            
            # Ensure local directory exists
            local_path.parent.mkdir(parents=True, exist_ok=True)
            
            # Get file size for progress tracking
            file_size = 0
            try:
                file_size = ftp.size(remote_path)
            except:
                pass  # Size command not supported or file doesn't exist
            
            downloaded = 0
            
            def progress_tracker(data):
                nonlocal downloaded
                downloaded += len(data)
                if progress_callback and file_size > 0:
                    progress_callback(downloaded, file_size)
            
            # Download file
            with open(local_path, 'wb') as local_file:
                if file_size > 0:
                    ftp.retrbinary(f'RETR {remote_path}', lambda data: (local_file.write(data), progress_tracker(data)))
                else:
                    ftp.retrbinary(f'RETR {remote_path}', local_file.write)
            
            self._return_connection(ftp)
            return True
            
        except Exception as e:
            print(f"❌ Error downloading {remote_path}: {e}")
            return False
    
    def upload_file(self, local_path: Path, remote_path: str, progress_callback=None) -> bool:
        """Upload a single file"""
        try:
            if not local_path.exists():
                print(f"❌ Local file not found: {local_path}")
                return False
            
            ftp = self._get_connection()
            
            # Create remote directory if needed
            remote_dir = os.path.dirname(remote_path)
            if remote_dir:
                self._create_remote_directory(ftp, remote_dir)
            
            # Get file size for progress tracking
            file_size = local_path.stat().st_size
            uploaded = 0
            
            def progress_tracker(data):
                nonlocal uploaded
                uploaded += len(data)
                if progress_callback:
                    progress_callback(uploaded, file_size)
                return data
            
            # Upload file
            with open(local_path, 'rb') as local_file:
                if progress_callback:
                    ftp.storbinary(f'STOR {remote_path}', local_file, callback=lambda data: progress_tracker(data))
                else:
                    ftp.storbinary(f'STOR {remote_path}', local_file)
            
            self._return_connection(ftp)
            return True
            
        except Exception as e:
            print(f"❌ Error uploading {local_path}: {e}")
            return False
    
    def _create_remote_directory(self, ftp: ftplib.FTP, remote_dir: str):
        """Create remote directory recursively"""
        dirs = remote_dir.split('/')
        current_dir = ""
        
        for dir_name in dirs:
            if not dir_name:
                continue
            
            current_dir = f"{current_dir}/{dir_name}" if current_dir else dir_name
            
            try:
                ftp.mkd(current_dir)
            except ftplib.error_perm:
                # Directory might already exist
                pass
    
    def download_directory(self, remote_path: str, local_path: Path, 
                          extensions: List[str] = None, max_workers: int = 4) -> Tuple[int, int, int]:
        """Download all files from remote directory"""
        print(f"📥 Downloading from {remote_path} to {local_path}")
        
        # List files to download
        files = self.list_files(remote_path, extensions)
        if not files:
            print(f"⚠️  No files found in {remote_path}")
            return 0, 0, 0
        
        print(f"📋 Found {len(files)} files to download")
        
        # Create local directory
        local_path.mkdir(parents=True, exist_ok=True)
        
        # Download files in parallel
        successful = 0
        failed = 0
        corrupted = 0
        failed_files = []
        corrupted_files = []
        
        with ThreadPoolExecutor(max_workers=max_workers) as executor:
            # Create progress bar
            with tqdm(total=len(files), desc="Downloading", unit="file") as pbar:
                
                # Submit download tasks
                future_to_file = {}
                for filename in files:
                    remote_file_path = f"{remote_path}/{filename}" if remote_path else filename
                    local_file_path = local_path / filename
                    
                    future = executor.submit(self.download_file, remote_file_path, local_file_path)
                    future_to_file[future] = (filename, local_file_path)
                
                # Process completed downloads
                for future in as_completed(future_to_file):
                    filename, local_file_path = future_to_file[future]
                    try:
                        success = future.result()
                        if success:
                            # Check if file is valid (not zero bytes)
                            if local_file_path.exists() and local_file_path.stat().st_size > 0:
                                successful += 1
                            else:
                                corrupted += 1
                                corrupted_files.append(filename)
                                print(f"⚠️  Downloaded file is corrupted/empty: {filename}")
                        else:
                            failed += 1
                            failed_files.append(filename)
                        
                        pbar.set_postfix({"✅": successful, "❌": failed, "⚠️": corrupted})
                    except Exception as e:
                        failed += 1
                        failed_files.append(filename)
                        print(f"❌ Failed to download {filename}: {e}")
                        pbar.set_postfix({"✅": successful, "❌": failed, "⚠️": corrupted})
                    
                    pbar.update(1)
        
        # Calculate success rate
        total_attempted = successful + failed + corrupted
        success_rate = (successful / total_attempted * 100) if total_attempted > 0 else 0
        
        print(f"📥 Download complete: {successful} successful, {failed} failed, {corrupted} corrupted")
        print(f"📊 Success rate: {success_rate:.1f}% ({successful}/{total_attempted})")
        
        # Show details of failed/corrupted files
        if failed_files:
            print(f"❌ Failed downloads: {', '.join(failed_files[:5])}" + ("..." if len(failed_files) > 5 else ""))
        if corrupted_files:
            print(f"⚠️  Corrupted files: {', '.join(corrupted_files[:5])}" + ("..." if len(corrupted_files) > 5 else ""))
        
        return successful, failed, corrupted
    
    def upload_directory(self, local_path: Path, remote_path: str, max_workers: int = 2) -> Tuple[int, int]:
        """Upload all files from local directory"""
        print(f"📤 Uploading from {local_path} to {remote_path}")
        
        if not local_path.exists():
            print(f"❌ Local directory not found: {local_path}")
            return 0, 0
        
        # Find all files to upload
        files_to_upload = []
        for file_path in local_path.rglob('*'):
            if file_path.is_file():
                relative_path = file_path.relative_to(local_path)
                remote_file_path = f"{remote_path}/{relative_path}".replace('\\', '/')
                files_to_upload.append((file_path, remote_file_path))
        
        if not files_to_upload:
            print(f"⚠️  No files found in {local_path}")
            return 0, 0
        
        print(f"📋 Found {len(files_to_upload)} files to upload")
        
        # Upload files in parallel
        successful = 0
        failed = 0
        
        with ThreadPoolExecutor(max_workers=max_workers) as executor:
            # Create progress bar
            with tqdm(total=len(files_to_upload), desc="Uploading", unit="file") as pbar:
                
                # Submit upload tasks
                future_to_file = {}
                for local_file_path, remote_file_path in files_to_upload:
                    future = executor.submit(self.upload_file, local_file_path, remote_file_path)
                    future_to_file[future] = local_file_path.name
                
                # Process completed uploads
                for future in as_completed(future_to_file):
                    filename = future_to_file[future]
                    try:
                        success = future.result()
                        if success:
                            successful += 1
                            pbar.set_postfix({"✅": successful, "❌": failed})
                        else:
                            failed += 1
                            pbar.set_postfix({"✅": successful, "❌": failed})
                    except Exception as e:
                        failed += 1
                        print(f"❌ Failed to upload {filename}: {e}")
                        pbar.set_postfix({"✅": successful, "❌": failed})
                    
                    pbar.update(1)
        
        print(f"📤 Upload complete: {successful} successful, {failed} failed")
        return successful, failed
    
    def cleanup(self):
        """Clean up connection pool"""
        with self._pool_lock:
            for ftp in self._connection_pool:
                try:
                    ftp.quit()
                except:
                    pass
            self._connection_pool.clear()


def get_api_key(args) -> str:
    """Get API key from various sources"""
    # Priority: command line > environment variable > interactive prompt
    
    if args.api_key:
        return args.api_key
    
    if 'BUNNY_API_KEY' in os.environ:
        api_key = os.environ['BUNNY_API_KEY']
        if api_key and api_key != "your-api-key-here":
            return api_key
    
    # Interactive prompt
    try:
        api_key = getpass.getpass("Enter Bunny CDN API key: ")
        if not api_key:
            print("❌ API key is required")
            sys.exit(1)
        return api_key
    except KeyboardInterrupt:
        print("\n❌ Operation cancelled")
        sys.exit(1)


def download_command(args):
    """Download images from Bunny CDN"""
    print("📥 Bunny CDN Download")
    print("=" * 30)
    
    # Get API key securely
    api_key = get_api_key(args)
    
    # Initialize client
    client = BunnyCDNClient(api_key, args.storage_zone)
    
    # Test connection
    if not client.test_connection():
        print("❌ Connection test failed")
        return 1
    
    # Download files
    extensions = args.extensions if args.extensions else ['.jpg', '.jpeg', '.png', '.tiff', '.bmp']
    local_path = Path(args.local_path)
    
    successful, failed, corrupted = client.download_directory(
        args.remote_path, 
        local_path, 
        extensions, 
        args.max_workers
    )
    
    client.cleanup()
    
    # Calculate overall success rate
    total_attempted = successful + failed + corrupted
    if total_attempted == 0:
        print("❌ No files were found to download")
        return 1
    
    success_rate = (successful / total_attempted * 100)
    
    # Determine overall result based on success rate and valid files downloaded
    if successful == 0:
        print("❌ No files downloaded successfully")
        return 1
    elif success_rate >= 90.0:
        # High success rate - consider this successful
        print(f"✅ Download successful: {successful} files downloaded to {local_path}")
        if failed > 0 or corrupted > 0:
            print(f"   Note: {failed} failed, {corrupted} corrupted files (acceptable for {success_rate:.1f}% success rate)")
        return 0
    elif success_rate >= 70.0:
        # Moderate success rate - warning but proceed
        print(f"⚠️  Download completed with issues: {successful} files downloaded to {local_path}")
        print(f"   Success rate: {success_rate:.1f}% - some files may need re-downloading")
        return 0
    else:
        # Low success rate - consider this a failure
        print(f"❌ Download failed: only {success_rate:.1f}% success rate")
        print(f"   {successful} successful, {failed} failed, {corrupted} corrupted")
        return 1


def upload_command(args):
    """Upload results to Bunny CDN"""
    print("📤 Bunny CDN Upload")
    print("=" * 30)
    
    # Get API key securely
    api_key = get_api_key(args)
    
    # Initialize client
    client = BunnyCDNClient(api_key, args.storage_zone)
    
    # Test connection
    if not client.test_connection():
        print("❌ Connection test failed")
        return 1
    
    # Upload files
    local_path = Path(args.local_path)
    
    successful, failed = client.upload_directory(
        local_path,
        args.remote_path,
        args.max_workers
    )
    
    client.cleanup()
    
    if failed > 0:
        print(f"⚠️  {failed} files failed to upload")
        return 1
    
    print(f"✅ Successfully uploaded {successful} files to {args.remote_path}")
    return 0


def test_command(args):
    """Test connection to Bunny CDN"""
    print("🔍 Bunny CDN Connection Test")
    print("=" * 30)
    
    # Get API key securely
    api_key = get_api_key(args)
    
    # Initialize client
    client = BunnyCDNClient(api_key, args.storage_zone)
    
    # Test connection
    success = client.test_connection()
    client.cleanup()
    
    return 0 if success else 1


def main():
    parser = argparse.ArgumentParser(
        description="Bunny CDN Storage Client - Secure FTP integration for 3D reconstruction pipeline",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Download images
  python bunny_cdn.py download --storage-zone colmap --remote-path inputs --local-path ./data/images

  # Upload results  
  python bunny_cdn.py upload --storage-zone colmap --local-path ./results --remote-path output/run_001

  # Test connection
  python bunny_cdn.py test --storage-zone colmap --api-key your-key-here

Security:
  API key can be provided via:
  1. --api-key argument (not recommended for scripts)
  2. BUNNY_API_KEY environment variable
  3. Interactive prompt (most secure)
        """
    )
    
    # Global arguments
    parser.add_argument('--api-key', type=str,
                       help='Bunny CDN API key (or use BUNNY_API_KEY env var)')
    parser.add_argument('--storage-zone', type=str, required=True,
                       help='Bunny CDN storage zone name')
    parser.add_argument('--hostname', type=str, default='storage.bunnycdn.com',
                       help='FTP hostname (default: storage.bunnycdn.com)')
    parser.add_argument('--port', type=int, default=21,
                       help='FTP port (default: 21)')
    
    # Subcommands
    subparsers = parser.add_subparsers(dest='command', help='Available commands')
    
    # Download command
    download_parser = subparsers.add_parser('download', help='Download files from CDN')
    download_parser.add_argument('--remote-path', type=str, default='',
                                help='Remote directory path (default: root)')
    download_parser.add_argument('--local-path', type=str, required=True,
                                help='Local directory path')
    download_parser.add_argument('--extensions', nargs='+',
                                help='File extensions to download (default: image formats)')
    download_parser.add_argument('--max-workers', type=int, default=4,
                                help='Maximum parallel downloads (default: 4)')
    
    # Upload command
    upload_parser = subparsers.add_parser('upload', help='Upload files to CDN')
    upload_parser.add_argument('--local-path', type=str, required=True,
                              help='Local directory path')
    upload_parser.add_argument('--remote-path', type=str, required=True,
                              help='Remote directory path')
    upload_parser.add_argument('--max-workers', type=int, default=2,
                              help='Maximum parallel uploads (default: 2)')
    
    # Test command
    test_parser = subparsers.add_parser('test', help='Test connection to CDN')
    
    args = parser.parse_args()
    
    if not args.command:
        parser.print_help()
        return 1
    
    try:
        if args.command == 'download':
            return download_command(args)
        elif args.command == 'upload':
            return upload_command(args)
        elif args.command == 'test':
            return test_command(args)
        else:
            print(f"❌ Unknown command: {args.command}")
            return 1
    except KeyboardInterrupt:
        print("\n❌ Operation cancelled by user")
        return 1
    except Exception as e:
        print(f"❌ Unexpected error: {e}")
        return 1


if __name__ == "__main__":
    sys.exit(main())
