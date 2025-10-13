#!/usr/bin/env python3

import subprocess
import json

def get_media_info():
    try:
        # Try to get media info from playerctl
        result = subprocess.run(['playerctl', 'metadata', '--format', '{"artist": "{{ artist }}", "title": "{{ title }}", "status": "{{ status }}"}'], 
                              capture_output=True, text=True, timeout=5)
        
        if result.returncode == 0 and result.stdout.strip():
            data = json.loads(result.stdout.strip())
            
            # Format output
            if data.get('title') and data.get('artist'):
                text = f"{data['artist']} - {data['title']}"
            elif data.get('title'):
                text = data['title']
            else:
                text = "No media"
                
            # Determine icon based on status
            if data.get('status') == 'Playing':
                icon = ""
            elif data.get('status') == 'Paused':
                icon = ""
            else:
                icon = ""
                
            return {"text": text, "class": data.get('status', 'stopped'), "icon": icon}
        else:
            return {"text": "No media", "class": "stopped", "icon": ""}
            
    except (subprocess.TimeoutExpired, subprocess.CalledProcessError, json.JSONDecodeError, FileNotFoundError):
        return {"text": "No media", "class": "stopped", "icon": ""}

if __name__ == "__main__":
    info = get_media_info()
    print(json.dumps(info))