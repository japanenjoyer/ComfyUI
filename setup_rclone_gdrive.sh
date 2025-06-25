#!/bin/bash

echo "=== Rclone Google Drive Setup ==="
echo
echo "This script will help you configure rclone with Google Drive."
echo "You'll need to authenticate through your web browser."
echo
echo "Press Enter to continue..."
read

# Start rclone config
~/.local/bin/rclone config

echo
echo "Configuration complete!"
echo
echo "To test your configuration, run:"
echo "  rclone ls gdrive:"
echo
echo "To backup your ComfyUI models, you can use:"
echo "  rclone copy models/ gdrive:ComfyUI/models/ -P"