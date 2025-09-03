import os
import json
from collections import defaultdict

def generate_manifest():
    manifest = []
    platforms_dir = "."
    
    # Walk through all directories
    for root, dirs, files in os.walk(platforms_dir):
        # Skip the current directory itself
        if root == platforms_dir:
            continue
            
        # Extract platform and subfolder from path
        path_parts = root.split(os.sep)
        
        if len(path_parts) >= 2:
            platform = path_parts[1]
            subfolder = "non" if len(path_parts) == 2 else path_parts[2]
            
            # Find all JSON files in this directory
            json_files = [f for f in files if f.endswith('.json')]
            
            if json_files:
                # Check if this platform+subfolder already exists in manifest
                found = False
                for item in manifest:
                    if item['platform'] == platform and item['subfolder'] == subfolder:
                        item['files'].extend(json_files)
                        found = True
                        break
                
                if not found:
                    manifest.append({
                        "platform": platform,
                        "subfolder": subfolder,
                        "files": json_files
                    })
    
    return manifest

if __name__ == "__main__":
    manifest_data = generate_manifest()
    
    # Sort the manifest for consistency
    manifest_data.sort(key=lambda x: (x['platform'], x['subfolder']))
    
    # Write to manifest.json with compact format
    with open('manifest.json', 'w') as f:
        f.write('[')
        for i, item in enumerate(manifest_data):
            if i > 0:
                f.write(',')
            f.write(json.dumps(item, separators=(',', ':')))
        f.write(']')
    
    print("manifest.json created successfully with compact format!")
    print(f"Found {len(manifest_data)} platform entries")
