#!/usr/bin/env python3

# Simple YouTube downloader - processes URLs from List.txt and cleans up after success

import os
import subprocess
import sys

URL_FILE = "List.txt"

def remove_url_from_file(url_to_remove):
    """Remove a specific URL from the file immediately"""
    try:
        with open(URL_FILE, 'r') as f:
            lines = f.readlines()
        
        with open(URL_FILE, 'w') as f:
            for line in lines:
                if line.strip() != url_to_remove:
                    f.write(line)
    except Exception as e:
        print(f"Warning: Could not remove URL from file: {e}")

def main():
    # Check if URL file exists
    if not os.path.exists(URL_FILE):
        print(f"No URLs to process: {URL_FILE} not found")
        return
    
    success_count = 0
    total_count = 0
    
    # Process URLs one by one, removing immediately after success
    while True:
        # Read current URLs from file
        with open(URL_FILE, 'r') as f:
            urls = [line.strip() for line in f if line.strip() and not line.strip().startswith('#')]
        
        if not urls:
            break
        
        url = urls[0]  # Process first URL
        total_count += 1
        
        print(f"Downloading: {url}")
        
        try:
            # Download with yt-dlp (simple command)
            result = subprocess.run(['yt-dlp', url], check=True, capture_output=False)
            print(f"Successfully downloaded: {url}")
            
            # Remove URL immediately after successful download
            remove_url_from_file(url)
            print(f"Removed URL from list: {url}")
            success_count += 1
            
        except subprocess.CalledProcessError:
            print(f"Failed to download: {url}")
            # Keep failed URL in file, but break to avoid infinite loop
            break
        except FileNotFoundError:
            print("Error: yt-dlp not found. Please install yt-dlp.")
            sys.exit(1)
    
    if total_count > 0:
        print(f"Processing complete. {success_count}/{total_count} URLs downloaded successfully")

if __name__ == "__main__":
    main()
