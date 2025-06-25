#!/bin/bash

# ComfyUI Models Backup Script
# This script backs up all ComfyUI models to Google Drive

RCLONE_PATH="$HOME/.local/bin/rclone"
REMOTE_NAME="gdrive"  # Change this if you used a different name during rclone config
GDRIVE_FOLDER="ComfyUI"
COMFYUI_PATH="$(dirname "$0")"

echo "=== ComfyUI Models Backup to Google Drive ==="
echo "Starting backup at $(date)"
echo

# Check if rclone is configured
if ! $RCLONE_PATH listremotes | grep -q "^${REMOTE_NAME}:"; then
    echo "Error: Remote '$REMOTE_NAME' not found in rclone config"
    echo "Please run: ./setup_rclone_gdrive.sh first"
    exit 1
fi

# Create main backup folder on Google Drive
echo "Creating backup folder structure on Google Drive..."
$RCLONE_PATH mkdir "${REMOTE_NAME}:${GDRIVE_FOLDER}" 2>/dev/null

# Backup models directory
echo "Backing up models directory..."
$RCLONE_PATH copy \
    "$COMFYUI_PATH/models/" \
    "${REMOTE_NAME}:${GDRIVE_FOLDER}/models/" \
    --progress \
    --transfers 4 \
    --checkers 8 \
    --contimeout 60s \
    --timeout 300s \
    --retries 3 \
    --low-level-retries 10 \
    --exclude "*.tmp" \
    --exclude "*.part"

echo
echo "Backup completed at $(date)"

# Show summary
echo
echo "=== Backup Summary ==="
$RCLONE_PATH size "${REMOTE_NAME}:${GDRIVE_FOLDER}/models/"

echo
echo "To view your backed up files, run:"
echo "  $RCLONE_PATH ls ${REMOTE_NAME}:${GDRIVE_FOLDER}/models/"