# OAK-D Pro Quad Streaming System

**Production-ready GStreamer receivers** with advanced real-time overlays for OAK-D Pro quad video streams.

Displays **RGB + Left + Right cameras + Depth stream simultaneously** with telemetry, FPS, timestamps, and monitoring.

## ⚡ Quick Start (TL;DR)

```bash
# Start Pi quad streamer (all 4 streams including depth)
./ssh_pi_robust.sh "cd /home/ivyspec/ivy_streamer && source venv/bin/activate && python quad_streamer.py" &

# Start PC video receivers (all 4 streams)
./test_quad_advanced_overlay.sh
```

**OR automated startup:**
```bash
# Complete setup with automated Pi management
./start_quad_advanced_overlay.sh
```

## Quick Setup

### PC Side (This Repository)
```bash
# 1. Clone this repository
git clone https://github.com/rbivy/ivy_streamer_pc.git
cd ivy_streamer_pc

# 2. Install GStreamer (Ubuntu/Debian)
sudo apt install gstreamer1.0-tools gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-bad

# 3. Make scripts executable
chmod +x *.sh
```

### Pi Side Setup (Required First)
```bash
# Pi repository: https://github.com/rbivy/ivy_streamer_pi
# SSH to Pi and start the quad streamer using the virtual environment
ssh ivyspec@192.168.1.202
cd /home/ivyspec/ivy_streamer
source venv/bin/activate
python quad_streamer.py  # All 4 streams including depth
```

**Quad Streamer Features:**
- **RGB**: 1920x1080 @ 30fps (H.264, 8Mbps) - Port 5000
- **Left Mono**: 1280x720 @ 30fps (H.264, 3Mbps) - Port 5001
- **Right Mono**: 1280x720 @ 30fps (H.264, 3Mbps) - Port 5002
- **Depth**: 1280x720 @ 30fps (JPEG-encoded) - Port 5003
- **Multithreaded**: 4 separate TCP servers for optimal performance
- **Real-time depth**: Stereo computation with HIGH_DETAIL preset

### Start Video Streaming

**Method 1: Automated Quad Streaming (Recommended)**
```bash
# Complete setup with automated Pi management
./start_quad_advanced_overlay.sh
```

**Method 2: Manual Step-by-Step**
```bash
# Start Pi quad streamer
./start_quad.sh

# Once Pi streams are ready, start PC receivers
./test_quad_advanced_overlay.sh
```

**Method 3: Manual Pi Control**
```bash
# Start Pi quad streamer manually via SSH
./ssh_pi_robust.sh "cd /home/ivyspec/ivy_streamer && source venv/bin/activate && python quad_streamer.py" &

# Wait for initialization, then start PC receiver
sleep 12 && ./test_quad_advanced_overlay.sh
```

**Method 4: Full Manual Setup**
```bash
# 1. First verify Pi connectivity (all 4 ports)
nc -zv 192.168.1.202 5000 5001 5002 5003

# 2. If ports are closed, start Pi streamer (see Pi Side Setup above)

# 3. Once Pi ports are open, start PC receiver
./test_quad_advanced_overlay.sh
```

## Video Display

### Quad Stream Receiver
```bash
./test_quad_advanced_overlay.sh
```
Shows:
- **4 simultaneous streams**: RGB + Left + Right + Depth
- **RGB/Left/Right**: H.264 streams with GStreamer overlays
- **Depth**: JPEG-encoded depth map with OpenCV display
- Stream name and resolution overlays
- Current timestamp overlays
- Real-time FPS counters
- **Depth visualization**: Real-time stereo-computed depth map in grayscale

**Performance**: ~25fps RGB, ~12-15fps stereo cameras, ~30fps depth computation

## Utility Scripts

### Pi Streamer Management
```bash
# Start Pi quad streamer with automatic cleanup (RECOMMENDED)
./start_quad.sh

# Stop Pi streamer
./ssh_pi_robust.sh "pkill -f quad_streamer.py"
```

### SSH and Pi Management
```bash
# Connect to Pi interactively
./ssh_pi_robust.sh

# Run command on Pi
./ssh_pi_robust.sh "command here"

# Start Pi streamer manually (alternative method)
./ssh_pi_robust.sh "cd /home/ivyspec/ivy_streamer && source venv/bin/activate && python quad_streamer.py"

# System diagnostics
./system_diagnostic.sh
```


## Network Requirements

- Pi streaming on ports 5000, 5001, 5002, 5003
- Same network as Raspberry Pi
- ~18 Mbps bandwidth for full resolution (4 streams)
- GStreamer and OpenCV installed on PC

## Features

- **Quad simultaneous streams**: RGB + Left + Right cameras + Depth
- **Real-time overlays**: FPS, resolution, timestamp
- **Depth visualization**: Stereo-computed depth maps
- **Status monitoring**: Process health checking
- **Multithreaded performance**: 4 separate TCP servers
- **Pi management**: SSH and remote control tools

## Files in this Repository

- `start_quad_advanced_overlay.sh` - **Complete setup** - Pi streamer + PC receivers (ONE COMMAND)
- `start_quad.sh` - **Smart Pi startup** with automatic cleanup (RECOMMENDED)
- `test_quad_advanced_overlay.sh` - **Quad receiver** with full telemetry overlays and depth
- `ssh_pi_robust.sh` - Robust SSH connection script for Pi management
- `system_diagnostic.sh` - Comprehensive system health check
- `requirements.txt` - System dependencies list
- `docs/` - Additional documentation and guides

## Advanced Features

### Real-time Overlays
- **Stream identification**: RGB/Left/Right/Depth camera labels
- **Resolution display**: Live resolution information
- **FPS monitoring**: Real-time frames per second
- **Timestamp overlay**: Current date and time
- **Performance stats**: Rendered/dropped frame counts
- **Depth visualization**: Grayscale depth maps with distance information

### Process Monitoring
- **Health checking**: Automatic process status monitoring
- **Error detection**: Failed stream alerts
- **Recovery guidance**: Troubleshooting suggestions
- **Resource usage**: CPU and memory monitoring

### Streaming Technology
- **H.264 encoding**: RGB, Left, Right cameras (hardware accelerated)
- **JPEG encoding**: Depth maps (optimized for real-time processing)
- **TCP streaming**: Reliable multi-client support
- **Multithreaded architecture**: 4 concurrent TCP servers

## Troubleshooting

### No Video Windows Appear
```bash
# 1. Use the smart startup script (handles cleanup automatically)
./start_quad.sh

# 2. If that fails, check ports manually
nc -zv 192.168.1.202 5000 5001 5002 5003

# 3. If ports are closed, try manual cleanup and restart
./ssh_pi_robust.sh "pkill -f quad_streamer.py"
sleep 3
./start_quad.sh

# 4. Verify GStreamer installation
gst-inspect-1.0 --version

# 5. Test individual stream
gst-launch-1.0 tcpclientsrc host=192.168.1.202 port=5000 ! h264parse ! avdec_h264 ! videoconvert ! autovideosink
```

### Poor Video Quality
- **Network**: Use wired Ethernet instead of WiFi (18+ Mbps required for 4 streams)
- **Bandwidth**: Reduce Pi streaming resolution/FPS if needed
- **CPU**: Close other applications consuming resources
- **Depth stream**: If depth is slow, check OpenCV installation

### Audio Issues
This system streams **video only**. Audio is not supported.

## Related Repositories

- **Pi Streamer**: https://github.com/rbivy/ivy_streamer_pi
- **Complete system** requires both repositories

## System Requirements

- **OS**: Ubuntu 20.04+ or Debian 11+
- **CPU**: Multi-core recommended for 4 simultaneous streams
- **RAM**: 4GB+ recommended
- **Network**: 100 Mbps+ Ethernet (Gigabit preferred)
- **Display**: Multiple monitor setup recommended
- **Dependencies**: GStreamer, OpenCV, Python3

## Version History

- **v2.0**: Quad-stream system with depth support
- **v1.0**: Initial triple-stream release
- Production-tested with real-time depth computation
- Optimized multithreaded architecture for 4 concurrent streams