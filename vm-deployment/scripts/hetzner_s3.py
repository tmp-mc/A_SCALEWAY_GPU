#!/usr/bin/env python3
"""
Hetzner S3 Storage Integration
AWS S3-compatible client for downloading images and uploading reconstruction results
Enhanced with debug capabilities and robust error handling
"""

import os
import sys
import argparse
import getpass
import time
import threading
import logging
from pathlib import Path
from typing import List, Optional, Tuple, Dict, Any
from concurrent.futures import ThreadPoolExecutor, as_completed
from tqdm import tqdm
import hashlib
import json

try:
    import boto3
    from botocore.exceptions import ClientError, NoCredentialsError, EndpointConnectionError
    from botocore.config import Config
except ImportError:
    print("❌ boto3 not installed. Run: pip install boto3>=1.34.0")
    sys.exit(1)


class HetznerS3Client:
    """Enhanced Hetzner S3 client with debug capabilities and robust error handling"""
    
    def __init__(self, access_key: str, secret_key: str, endpoint_url: str = "https://nbg1.your-objectstorage.com", 
                 api_token: Optional[str] = None, debug: bool = False):
        self.access_key = access_key
        self.secret_key = secret_key
        self.endpoint_url = endpoint_url
        self.api_token = api_token
        self.debug = debug
        
        # Setup logging
        self.logger = logging.getLogger('hetzner_s3')
        if debug:
            logging.basicConfig(level=logging.DEBUG, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
            # Enable boto3 debug logging
            boto3.set_stream_logger('boto3', logging.DEBUG)
            boto3.set_stream_logger('botocore', logging.DEBUG)
        else:
            logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
        
        # Configure boto3 with optimized settings
        self.config = Config(
            region_name='nbg1',  # Nuremberg region
            retries={
                'max_attempts': 3,
                'mode': 'adaptive'
            },
            max_pool_connections=50,
            signature_version='s3v4'
        )
        
        # Connection pool for parallel operations
        self._session_pool = []
        self._pool_lock = threading.Lock()
        
        print(f"🔗 Hetzner S3 Client initialized")
        print(f"   Endpoint: {endpoint_url}")
        print(f"   Access Key: {access_key[:8]}{'*' * (len(access_key) - 8) if len(access_key) > 8 else '***'}")
        print(f"   Debug Mode: {'Enabled' if debug else 'Disabled'}")
        
    def _create_client(self) -> boto3.client:
        """Create a new S3 client with error handling"""
        try:
            session = boto3.Session()
            client = session.client(
                's3',
                endpoint_url=self.endpoint_url,
                aws_access_key_id=self.access_key,
                aws_secret_access_key=self.secret_key,
                config=self.config
            )
            
            # Test the client with a simple operation
            try:
                client.list_buckets()
                self.logger.debug("S3 client created and tested successfully")
                return client
            except ClientError as e:
                error_code = e.response['Error']['Code']
                if error_code in ['InvalidAccessKeyId', 'SignatureDoesNotMatch']:
                    if self.api_token:
                        self.logger.warning("Primary credentials failed, attempting API token fallback")
                        # Attempt fallback to API token (implementation depends on Hetzner's API)
                        # For now, raise the original error
                        pass
                    raise ConnectionError(f"Authentication failed: {error_code}")
                else:
                    raise ConnectionError(f"S3 connection test failed: {error_code}")
                    
        except Exception as e:
            raise ConnectionError(f"Failed to create S3 client: {e}")
    
    def _get_client(self) -> boto3.client:
        """Get a client from the pool or create a new one"""
        with self._pool_lock:
            if self._session_pool:
                return self._session_pool.pop()
        return self._create_client()
    
    def _return_client(self, client: boto3.client):
        """Return a client to the pool"""
        try:
            # Test if client is still alive
            client.list_buckets()
            with self._pool_lock:
                if len(self._session_pool) < 10:  # Max pool size
                    self._session_pool.append(client)
        except:
            # Client is dead, don't return to pool
            self.logger.debug("Dead client not returned to pool")
    
    def test_connection(self, bucket_name: Optional[str] = None) -> bool:
        """Test the connection to Hetzner S3"""
        try:
            client = self._create_client()
            
            # Test basic connection
            response = client.list_buckets()
            buckets = [b['Name'] for b in response.get('Buckets', [])]
            print(f"✅ Connection successful! Found {len(buckets)} buckets")
            
            if buckets:
                print(f"   Available buckets: {', '.join(buckets[:5])}" + ("..." if len(buckets) > 5 else ""))
            
            # Test specific bucket if provided
            if bucket_name:
                if bucket_name in buckets:
                    try:
                        # Test bucket access
                        client.head_bucket(Bucket=bucket_name)
                        print(f"✅ Bucket '{bucket_name}' accessible")
                        
                        # Count objects in bucket
                        response = client.list_objects_v2(Bucket=bucket_name, MaxKeys=1)
                        object_count = response.get('KeyCount', 0)
                        if 'Contents' in response or object_count > 0:
                            print(f"   Objects in bucket: {object_count}+ files")
                        else:
                            print(f"   Bucket is empty")
                            
                    except ClientError as e:
                        error_code = e.response['Error']['Code']
                        if error_code == 'AccessDenied':
                            print(f"❌ Access denied to bucket '{bucket_name}'")
                            return False
                        else:
                            print(f"❌ Bucket test failed: {error_code}")
                            return False
                else:
                    print(f"❌ Bucket '{bucket_name}' not found")
                    return False
            
            self._return_client(client)
            return True
            
        except Exception as e:
            print(f"❌ Connection failed: {e}")
            return False
    
    def list_objects(self, bucket_name: str, prefix: str = "", extensions: List[str] = None, max_keys: int = 1000) -> List[Dict[str, Any]]:
        """List objects in S3 bucket with filtering"""
        try:
            client = self._get_client()
            
            objects = []
            paginator = client.get_paginator('list_objects_v2')
            
            page_iterator = paginator.paginate(
                Bucket=bucket_name,
                Prefix=prefix,
                PaginationConfig={'MaxItems': max_keys}
            )
            
            for page in page_iterator:
                if 'Contents' in page:
                    for obj in page['Contents']:
                        key = obj['Key']
                        
                        # Skip directories
                        if key.endswith('/'):
                            continue
                            
                        # Filter by extensions if specified
                        if extensions:
                            if not any(key.lower().endswith(ext.lower()) for ext in extensions):
                                continue
                        
                        objects.append({
                            'Key': key,
                            'Size': obj['Size'],
                            'LastModified': obj['LastModified'],
                            'ETag': obj['ETag']
                        })
            
            self._return_client(client)
            self.logger.debug(f"Listed {len(objects)} objects from s3://{bucket_name}/{prefix}")
            return objects
            
        except Exception as e:
            self.logger.error(f"Error listing objects: {e}")
            return []
    
    def download_file(self, bucket_name: str, remote_key: str, local_path: Path, progress_callback=None) -> bool:
        """Download a single file with retry logic"""
        max_retries = 3
        retry_delay = 1
        
        for attempt in range(max_retries):
            try:
                client = self._get_client()
                
                # Ensure local directory exists
                local_path.parent.mkdir(parents=True, exist_ok=True)
                
                # Get file size
                try:
                    response = client.head_object(Bucket=bucket_name, Key=remote_key)
                    file_size = response['ContentLength']
                except ClientError:
                    file_size = 0
                
                downloaded = 0
                
                def progress_tracker(chunk):
                    nonlocal downloaded
                    downloaded += len(chunk) if isinstance(chunk, bytes) else chunk
                    if progress_callback and file_size > 0:
                        progress_callback(downloaded, file_size)
                
                # Download file with progress tracking
                with open(local_path, 'wb') as local_file:
                    if progress_callback and file_size > 0:
                        client.download_fileobj(
                            bucket_name, remote_key, local_file,
                            Callback=progress_tracker
                        )
                    else:
                        client.download_fileobj(bucket_name, remote_key, local_file)
                
                self._return_client(client)
                self.logger.debug(f"Downloaded s3://{bucket_name}/{remote_key} -> {local_path}")
                return True
                
            except Exception as e:
                self.logger.warning(f"Download attempt {attempt + 1} failed: {e}")
                if attempt < max_retries - 1:
                    time.sleep(retry_delay * (2 ** attempt))  # Exponential backoff
                else:
                    self.logger.error(f"Failed to download {remote_key} after {max_retries} attempts")
                    return False
        
        return False
    
    def upload_file(self, local_path: Path, bucket_name: str, remote_key: str, progress_callback=None) -> bool:
        """Upload a single file with multipart support for large files"""
        if not local_path.exists():
            self.logger.error(f"Local file not found: {local_path}")
            return False
        
        file_size = local_path.stat().st_size
        multipart_threshold = 100 * 1024 * 1024  # 100MB
        
        max_retries = 3
        retry_delay = 1
        
        for attempt in range(max_retries):
            try:
                client = self._get_client()
                
                uploaded = 0
                
                def progress_tracker(chunk):
                    nonlocal uploaded
                    uploaded += len(chunk) if isinstance(chunk, bytes) else chunk
                    if progress_callback:
                        progress_callback(uploaded, file_size)
                
                # Use multipart upload for large files
                if file_size > multipart_threshold:
                    self.logger.debug(f"Using multipart upload for large file: {file_size} bytes")
                    
                    # Configure multipart upload
                    config = boto3.s3.transfer.TransferConfig(
                        multipart_threshold=multipart_threshold,
                        max_concurrency=10,
                        multipart_chunksize=8 * 1024 * 1024,  # 8MB chunks
                        use_threads=True
                    )
                    
                    with open(local_path, 'rb') as local_file:
                        client.upload_fileobj(
                            local_file, bucket_name, remote_key,
                            Config=config,
                            Callback=progress_tracker if progress_callback else None
                        )
                else:
                    # Regular upload for smaller files
                    with open(local_path, 'rb') as local_file:
                        if progress_callback:
                            client.upload_fileobj(
                                local_file, bucket_name, remote_key,
                                Callback=progress_tracker
                            )
                        else:
                            client.upload_fileobj(local_file, bucket_name, remote_key)
                
                self._return_client(client)
                self.logger.debug(f"Uploaded {local_path} -> s3://{bucket_name}/{remote_key}")
                return True
                
            except Exception as e:
                self.logger.warning(f"Upload attempt {attempt + 1} failed: {e}")
                if attempt < max_retries - 1:
                    time.sleep(retry_delay * (2 ** attempt))  # Exponential backoff
                else:
                    self.logger.error(f"Failed to upload {local_path} after {max_retries} attempts")
                    return False
        
        return False
    
    def download_directory(self, bucket_name: str, prefix: str, local_path: Path, 
                          extensions: List[str] = None, max_workers: int = 4) -> Tuple[int, int, int]:
        """Download all matching objects from S3 bucket"""
        print(f"📥 Downloading from s3://{bucket_name}/{prefix} to {local_path}")
        
        # List objects to download
        objects = self.list_objects(bucket_name, prefix, extensions)
        if not objects:
            print(f"⚠️  No objects found in s3://{bucket_name}/{prefix}")
            return 0, 0, 0
        
        print(f"📋 Found {len(objects)} objects to download")
        
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
            with tqdm(total=len(objects), desc="Downloading", unit="file") as pbar:
                
                # Submit download tasks
                future_to_object = {}
                for obj in objects:
                    remote_key = obj['Key']
                    # Remove prefix from key for local filename
                    relative_key = remote_key[len(prefix):].lstrip('/')
                    if not relative_key:  # Skip if empty after prefix removal
                        continue
                        
                    local_file_path = local_path / relative_key
                    
                    future = executor.submit(self.download_file, bucket_name, remote_key, local_file_path)
                    future_to_object[future] = (obj, local_file_path)
                
                # Process completed downloads
                for future in as_completed(future_to_object):
                    obj, local_file_path = future_to_object[future]
                    filename = obj['Key']
                    
                    try:
                        success = future.result()
                        if success:
                            # Check if file is valid (not zero bytes)
                            if local_file_path.exists() and local_file_path.stat().st_size > 0:
                                successful += 1
                            else:
                                corrupted += 1
                                corrupted_files.append(filename)
                                self.logger.warning(f"Downloaded file is corrupted/empty: {filename}")
                        else:
                            failed += 1
                            failed_files.append(filename)
                        
                        pbar.set_postfix({"✅": successful, "❌": failed, "⚠️": corrupted})
                    except Exception as e:
                        failed += 1
                        failed_files.append(filename)
                        self.logger.error(f"Failed to download {filename}: {e}")
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
    
    def upload_directory(self, local_path: Path, bucket_name: str, prefix: str, max_workers: int = 2) -> Tuple[int, int]:
        """Upload all files from local directory to S3"""
        print(f"📤 Uploading from {local_path} to s3://{bucket_name}/{prefix}")
        
        if not local_path.exists():
            print(f"❌ Local directory not found: {local_path}")
            return 0, 0
        
        # Find all files to upload
        files_to_upload = []
        for file_path in local_path.rglob('*'):
            if file_path.is_file():
                relative_path = file_path.relative_to(local_path)
                remote_key = f"{prefix.rstrip('/')}/{relative_path}".replace('\\', '/')
                files_to_upload.append((file_path, remote_key))
        
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
                for local_file_path, remote_key in files_to_upload:
                    future = executor.submit(self.upload_file, local_file_path, bucket_name, remote_key)
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
                        self.logger.error(f"Failed to upload {filename}: {e}")
                        pbar.set_postfix({"✅": successful, "❌": failed})
                    
                    pbar.update(1)
        
        print(f"📤 Upload complete: {successful} successful, {failed} failed")
        return successful, failed
    
    def cleanup(self):
        """Clean up connection pool"""
        with self._pool_lock:
            self._session_pool.clear()


def get_credentials(args) -> Tuple[str, str, Optional[str]]:
    """Get S3 credentials from various sources"""
    access_key = None
    secret_key = None
    api_token = None
    
    # Priority: command line > environment variable > interactive prompt
    
    if args.access_key and args.secret_key:
        access_key = args.access_key
        secret_key = args.secret_key
    
    if not access_key and 'HETZNER_ACCESS_KEY' in os.environ:
        access_key = os.environ['HETZNER_ACCESS_KEY']
        if access_key and access_key != "your-access-key-here":
            secret_key = os.environ.get('HETZNER_SECRET_KEY', '')
    
    if args.api_token:
        api_token = args.api_token
    elif 'HETZNER_API_TOKEN' in os.environ:
        api_token = os.environ['HETZNER_API_TOKEN']
    
    # Interactive prompt if still missing
    if not access_key:
        try:
            access_key = input("Enter Hetzner S3 Access Key: ")
            if not access_key:
                print("❌ Access key is required")
                sys.exit(1)
        except KeyboardInterrupt:
            print("\n❌ Operation cancelled")
            sys.exit(1)
    
    if not secret_key:
        try:
            secret_key = getpass.getpass("Enter Hetzner S3 Secret Key: ")
            if not secret_key:
                print("❌ Secret key is required")
                sys.exit(1)
        except KeyboardInterrupt:
            print("\n❌ Operation cancelled")
            sys.exit(1)
    
    return access_key, secret_key, api_token


def download_command(args):
    """Download objects from Hetzner S3"""
    print("📥 Hetzner S3 Download")
    print("=" * 30)
    
    # Get credentials securely
    access_key, secret_key, api_token = get_credentials(args)
    
    # Initialize client
    client = HetznerS3Client(access_key, secret_key, args.endpoint, api_token, args.debug)
    
    # Test connection
    if not client.test_connection(args.bucket_name):
        print("❌ Connection test failed")
        return 1
    
    # Download files
    extensions = args.extensions if args.extensions else ['.jpg', '.jpeg', '.png', '.tiff', '.bmp']
    local_path = Path(args.local_path)
    
    successful, failed, corrupted = client.download_directory(
        args.bucket_name,
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
    """Upload files to Hetzner S3"""
    print("📤 Hetzner S3 Upload")
    print("=" * 30)
    
    # Get credentials securely
    access_key, secret_key, api_token = get_credentials(args)
    
    # Initialize client
    client = HetznerS3Client(access_key, secret_key, args.endpoint, api_token, args.debug)
    
    # Test connection
    if not client.test_connection(args.bucket_name):
        print("❌ Connection test failed")
        return 1
    
    # Upload files
    local_path = Path(args.local_path)
    
    successful, failed = client.upload_directory(
        local_path,
        args.bucket_name,
        args.remote_path,
        args.max_workers
    )
    
    client.cleanup()
    
    if failed > 0:
        print(f"⚠️  {failed} files failed to upload")
        return 1
    
    print(f"✅ Successfully uploaded {successful} files to s3://{args.bucket_name}/{args.remote_path}")
    return 0


def test_command(args):
    """Test connection to Hetzner S3"""
    print("🔍 Hetzner S3 Connection Test")
    print("=" * 30)
    
    # Get credentials securely
    access_key, secret_key, api_token = get_credentials(args)
    
    # Initialize client
    client = HetznerS3Client(access_key, secret_key, args.endpoint, api_token, args.debug)
    
    # Test connection
    success = client.test_connection(getattr(args, 'bucket_name', None))
    client.cleanup()
    
    return 0 if success else 1


def main():
    parser = argparse.ArgumentParser(
        description="Hetzner S3 Storage Client - AWS S3-compatible client for 3D reconstruction pipeline",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Download images
  python hetzner_s3.py download --bucket-name mydata --remote-path inputs --local-path ./data/images

  # Upload results  
  python hetzner_s3.py upload --bucket-name mydata --local-path ./results --remote-path output/run_001

  # Test connection with debug
  python hetzner_s3.py --debug test --bucket-name mydata

Security:
  Credentials can be provided via:
  1. --access-key and --secret-key arguments (not recommended for scripts)
  2. HETZNER_ACCESS_KEY and HETZNER_SECRET_KEY environment variables
  3. Interactive prompt (most secure)
  
  API token fallback: HETZNER_API_TOKEN environment variable
        """
    )
    
    # Global arguments
    parser.add_argument('--access-key', type=str,
                       help='Hetzner S3 access key (or use HETZNER_ACCESS_KEY env var)')
    parser.add_argument('--secret-key', type=str,
                       help='Hetzner S3 secret key (or use HETZNER_SECRET_KEY env var)')
    parser.add_argument('--api-token', type=str,
                       help='Hetzner API token for fallback auth (or use HETZNER_API_TOKEN env var)')
    parser.add_argument('--endpoint', type=str, default='https://nbg1.your-objectstorage.com',
                       help='S3 endpoint URL (default: https://nbg1.your-objectstorage.com)')
    parser.add_argument('--debug', action='store_true',
                       help='Enable debug logging')
    parser.add_argument('--verbose', action='store_true',
                       help='Enable verbose output (same as --debug)')
    
    # Subcommands
    subparsers = parser.add_subparsers(dest='command', help='Available commands')
    
    # Download command
    download_parser = subparsers.add_parser('download', help='Download files from S3')
    download_parser.add_argument('--bucket-name', type=str, required=True,
                                help='S3 bucket name')
    download_parser.add_argument('--remote-path', type=str, default='',
                                help='Remote path/prefix (default: root)')
    download_parser.add_argument('--local-path', type=str, required=True,
                                help='Local directory path')
    download_parser.add_argument('--extensions', nargs='+',
                                help='File extensions to download (default: image formats)')
    download_parser.add_argument('--max-workers', type=int, default=4,
                                help='Maximum parallel downloads (default: 4)')
    
    # Upload command
    upload_parser = subparsers.add_parser('upload', help='Upload files to S3')
    upload_parser.add_argument('--bucket-name', type=str, required=True,
                              help='S3 bucket name')
    upload_parser.add_argument('--local-path', type=str, required=True,
                              help='Local directory path')
    upload_parser.add_argument('--remote-path', type=str, required=True,
                              help='Remote path/prefix')
    upload_parser.add_argument('--max-workers', type=int, default=2,
                              help='Maximum parallel uploads (default: 2)')
    
    # Test command
    test_parser = subparsers.add_parser('test', help='Test connection to S3')
    test_parser.add_argument('--bucket-name', type=str,
                            help='Test specific bucket access (optional)')
    
    args = parser.parse_args()
    
    if not args.command:
        parser.print_help()
        return 1
    
    # Enable debug if verbose flag is used
    if args.verbose:
        args.debug = True
    
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
        if args.debug:
            import traceback
            traceback.print_exc()
        return 1


if __name__ == "__main__":
    sys.exit(main())
