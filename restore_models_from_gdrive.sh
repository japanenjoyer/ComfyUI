#!/bin/bash

# ComfyUI Models Restore Script
# This script restores ComfyUI models from Google Drive

RCLONE_PATH="$HOME/.local/bin/rclone"
REMOTE_NAME="gdrive"  # Change this if you used a different name during rclone config
GDRIVE_FOLDER="ComfyUI"
COMFYUI_PATH="$(dirname "$0")"

echo "=== ComfyUI Models Restore from Google Drive ==="
echo "Starting restore at $(date)"
echo

# Check if rclone is configured
if ! $RCLONE_PATH listremotes | grep -q "^${REMOTE_NAME}:"; then
    echo "Error: Remote '$REMOTE_NAME' not found in rclone config"
    echo "Please run: ./setup_rclone_gdrive.sh first"
    exit 1
fi

# Ask for confirmation
echo "WARNING: This will download models from Google Drive to your local models directory."
echo "Existing files with the same names will be overwritten."
echo
read -p "Do you want to continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Restore cancelled."
    exit 1
fi

# Create models directory if it doesn't exist
mkdir -p "$COMFYUI_PATH/models"

# Restore models directory
echo "Restoring models from Google Drive..."
$RCLONE_PATH copy \
    "${REMOTE_NAME}:${GDRIVE_FOLDER}/models/" \
    "$COMFYUI_PATH/models/" \
    --progress \
    --transfers 4 \
    --checkers 8 \
    --contimeout 60s \
    --timeout 300s \
    --retries 3 \
    --low-level-retries 10

echo
echo "Restore completed at $(date)"

# Show summary
echo
echo "=== Restore Summary ==="
echo "Local models directory size:"
du -sh "$COMFYUI_PATH/models/"