# Google Cloud GPU Setup for ComfyUI

This guide explains how to use Google Cloud GPUs with your local ComfyUI deployment for heavy video generation tasks.

## Architecture Overview

Your setup will consist of:
- **Local ComfyUI**: Your existing server for workflow design and light tasks
- **GCloud ComfyUI**: A GPU-powered instance for heavy processing
- **Bridge Nodes**: Custom nodes that delegate work to the cloud instance

## Step 1: Set Up Google Cloud GPU Instance

### 1.1 Create a GPU VM Instance

```bash
# Using gcloud CLI
gcloud compute instances create comfyui-gpu \
    --zone=us-central1-a \
    --machine-type=n1-highmem-8 \
    --accelerator=type=nvidia-tesla-t4,count=1 \
    --image-family=pytorch-latest-gpu \
    --image-project=deeplearning-platform-release \
    --boot-disk-size=200GB \
    --maintenance-policy=TERMINATE \
    --restart-on-failure
```

For video generation, recommended GPU options:
- **T4** (16GB): Good for smaller videos, most cost-effective
- **V100** (16GB): Faster processing, moderate cost
- **A100** (40GB): Best for large videos (Mochi, Cosmos), highest cost

### 1.2 SSH into the instance and install ComfyUI

```bash
# SSH into instance
gcloud compute ssh comfyui-gpu --zone=us-central1-a

# Install ComfyUI
git clone https://github.com/comfyanonymous/ComfyUI.git
cd ComfyUI
pip install -r requirements.txt

# Install video-specific requirements
pip install imageio-ffmpeg opencv-python

# Download your models (example for Mochi)
cd models/diffusion_models
wget [your-mochi-model-url]
```

### 1.3 Configure ComfyUI for Remote Access

```bash
# Start ComfyUI with external access
python main.py --listen 0.0.0.0 --port 8188
```

### 1.4 Set up Firewall Rules

```bash
# Allow access to ComfyUI port
gcloud compute firewall-rules create allow-comfyui \
    --allow tcp:8188 \
    --source-ranges=YOUR_LOCAL_IP/32 \
    --description="Allow ComfyUI access"
```

## Step 2: Install Bridge Nodes Locally

The custom nodes I created (`remote_gpu_executor.py` and `gcloud_gpu_bridge.py`) are now in your `custom_nodes` folder. 

Restart your local ComfyUI to load them.

## Step 3: Using the Remote GPU

### Option A: Simple Remote Execution

1. In your local ComfyUI, add a "GCloud GPU Config" node
2. Enter your GCloud instance's external IP
3. Use "GCloud Video Generation" node for video tasks
4. The node will handle sending the job to GCloud and retrieving results

### Option B: Advanced Workflow Splitting

For more control, you can:
1. Design your workflow locally
2. Use "Remote GPU Executor" nodes for GPU-intensive parts
3. Keep preprocessing/postprocessing local

Example workflow:
```
[Load Image] -> [Preprocess Locally] -> [Remote GPU Executor] -> [Postprocess Locally] -> [Save]
```

## Step 4: Cost Optimization

### Auto-shutdown Script

Add this to your GCloud instance to prevent forgotten instances:

```bash
#!/bin/bash
# /home/user/auto_shutdown.sh

# Check if ComfyUI has been idle for 30 minutes
IDLE_TIME=1800
LAST_MODIFIED=$(find /home/user/ComfyUI/output -type f -mmin -30 | wc -l)

if [ $LAST_MODIFIED -eq 0 ]; then
    echo "No activity for 30 minutes, shutting down..."
    sudo shutdown -h now
fi
```

Add to crontab:
```bash
*/5 * * * * /home/user/auto_shutdown.sh
```

### Preemptible Instances

For 70% cost savings (but can be terminated):
```bash
gcloud compute instances create comfyui-gpu-preempt \
    --zone=us-central1-a \
    --machine-type=n1-highmem-8 \
    --accelerator=type=nvidia-tesla-t4,count=1 \
    --preemptible \
    --image-family=pytorch-latest-gpu \
    --image-project=deeplearning-platform-release
```

## Step 5: Model Management

### Sync Models Between Local and Cloud

Use the "GCloud Model Sync" node to:
- List available models on remote instance
- Verify model compatibility
- Plan model uploads

### Persistent Storage for Models

Create a persistent disk for models:
```bash
# Create disk
gcloud compute disks create comfyui-models \
    --size=500GB \
    --zone=us-central1-a

# Attach to instance
gcloud compute instances attach-disk comfyui-gpu \
    --disk=comfyui-models \
    --zone=us-central1-a

# Mount in instance
sudo mkfs.ext4 /dev/sdb
sudo mkdir /mnt/models
sudo mount /dev/sdb /mnt/models

# Link to ComfyUI
ln -s /mnt/models /home/user/ComfyUI/models
```

## Step 6: Security Best Practices

1. **Use VPN or SSH Tunnel** instead of exposing port 8188:
   ```bash
   # SSH tunnel from local to GCloud
   gcloud compute ssh comfyui-gpu --zone=us-central1-a -- -L 8188:localhost:8188
   ```

2. **Add Authentication** to the custom nodes (API key in config)

3. **Use Cloud IAM** for access control

4. **Enable HTTPS** with a reverse proxy (nginx)

## Troubleshooting

### Connection Issues
- Check firewall rules: `gcloud compute firewall-rules list`
- Verify instance is running: `gcloud compute instances list`
- Test connectivity: `curl http://[EXTERNAL_IP]:8188/system_stats`

### Performance Issues
- Monitor GPU usage: `nvidia-smi` on the instance
- Check memory: Ensure your model fits in GPU memory
- Network speed: Large images/videos need good bandwidth

### Cost Monitoring
```bash
# Set up budget alerts
gcloud billing budgets create \
    --billing-account=YOUR_BILLING_ACCOUNT \
    --display-name="ComfyUI GPU Budget" \
    --budget-amount=100 \
    --threshold-rule=percent=90
```

## Example Video Generation Workflow

1. Local: Load/prepare prompts and settings
2. Local: "GCloud Video Generation" node with:
   - Model: "mochi" or "cosmos"
   - Prompt: Your text
   - Settings: steps=30, cfg=7.5
3. Cloud: Processes video generation
4. Local: Receives generated frames
5. Local: Post-processing and save

This setup allows you to leverage powerful cloud GPUs while maintaining your local workflow design environment!