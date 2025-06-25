# ComfyUI Google Drive Backup & Colab Usage Guide

## Local Backup Commands

### Full Backup
```bash
./backup_models_to_gdrive.sh
```

### Selective Backup (Faster)
```bash
# Backup only checkpoints
~/.local/bin/rclone copy models/checkpoints/ gdrive:ComfyUI/models/checkpoints/ -P

# Backup only LoRAs
~/.local/bin/rclone copy models/loras/ gdrive:ComfyUI/models/loras/ -P

# Backup only VAE files
~/.local/bin/rclone copy models/vae/ gdrive:ComfyUI/models/vae/ -P
```

### Check Backup Status
```bash
# List all backed up models
~/.local/bin/rclone ls gdrive:ComfyUI/models/

# Check total size
~/.local/bin/rclone size gdrive:ComfyUI/models/
```

## Using with Google Colab

1. **Upload the notebook**: Upload `ComfyUI_Colab_with_Drive.ipynb` to your Google Drive or open directly in Colab

2. **Set GPU**: Runtime → Change runtime type → T4 GPU (or better)

3. **Run cells in order**: The notebook will:
   - Mount your Google Drive
   - Install ComfyUI
   - Create symbolic links to your models (no copying needed!)
   - Start ComfyUI with a public URL

4. **Access ComfyUI**: Click the cloudflare URL that appears

## Benefits of This Setup

1. **No model uploads to Colab**: Models stay in Google Drive, accessed via symbolic links
2. **Instant access**: No waiting for model transfers each session
3. **Shared models**: Same models available locally and in Colab
4. **Space efficient**: Colab disk space is preserved
5. **Persistent**: Models remain in Drive between sessions

## Optimization Tips

### For Large Model Collections
If you have many models but only use some in Colab, create a separate backup:
```bash
# Create a "colab-models" folder with only essential models
~/.local/bin/rclone copy models/checkpoints/flux1-dev-fp8.safetensors gdrive:ComfyUI/colab-models/checkpoints/ -P
~/.local/bin/rclone copy models/checkpoints/dreamshaper_8.safetensors gdrive:ComfyUI/colab-models/checkpoints/ -P
```

### For Faster Colab Loading
Modify the notebook to only link specific models:
```python
# Instead of linking entire models folder, link only what you need
!ln -s /content/drive/MyDrive/ComfyUI/models/checkpoints/flux1-dev-fp8.safetensors /content/ComfyUI/models/checkpoints/
```

## Restore Models Locally
```bash
./restore_models_from_gdrive.sh
```

## Sync Changes
To sync new models added locally:
```bash
# This only uploads new/changed files
./backup_models_to_gdrive.sh
```