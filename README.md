# OAK-D Pro PC Receivers

**Production-ready GStreamer receivers** with advanced real-time overlays for OAK-D Pro quad video streams.

Displays **RGB + Left + Right cameras + Depth stream simultaneously** with telemetry, FPS, timestamps, and monitoring.

## ⚡ Quick Start (TL;DR)

```bash
# Start Pi quad streamer (all 4 streams including depth)
./ssh_pi_robust.sh "cd /home/ivyspec/ivy_streamer && source venv/bin/activate && python quad_streamer.py" &

# Start PC video receivers (all 4 streams)
./test_quad_advanced_overlay.sh
```

**OR for legacy triple streams:**
```bash
# Complete triple setup
./start_triple_advanced_overlay.sh
```

**Legacy triple streams (without depth):**
```bash
# Complete triple setup
./start_triple_advanced_overlay.sh

# OR step-by-step
./start_triple.sh
./test_triple_advanced_overlay.sh
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
python quad_streamer.py  # All 4 streams including depth (WORKING)
# OR
python triple_streamer.py      # Legacy triple streams only
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
# Smart quad startup with depth stream
./start_quad.sh

# Once Pi streams are ready, start PC receivers with depth
./test_quad_advanced_overlay.sh
```

**Method 2: Legacy Triple Streaming**
```bash
# Smart startup script with automatic cleanup
./start_triple.sh

# Once Pi streams are ready, start PC receivers
./test_triple_advanced_overlay.sh
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
# 1. First verify Pi connectivity (including depth port)
nc -zv 192.168.1.202 5000 5001 5002 5003

# 2. If ports are closed, start Pi streamer (see Pi Side Setup above)

# 3. Once Pi ports are open, start PC receiver
./test_quad_advanced_overlay.sh
```

## Receiver Scripts

### Quad Streams with Depth (Recommended)
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

### Advanced Triple Overlays (Legacy)
```bash
./test_triple_advanced_overlay.sh
```
Shows:
- **3 simultaneous streams**: RGB + Left + Right
- Stream name and resolution (top left)
- Current timestamp (top right)
- Real-time FPS counter (bottom)
- Status monitoring every 5 seconds

### Basic Overlays
```bash
./test_triple_overlay.sh
```
Shows:
- FPS counter only

### Simple Receivers
```bash
./test_triple.sh
```
No overlays, minimal CPU usage

## Utility Scripts

### Pi Streamer Management
```bash
# Start Pi streamer with automatic cleanup (RECOMMENDED)
./start_triple.sh

# Stop Pi streamer
./ssh_pi_robust.sh "pkill -f triple_streamer.py"
```

### SSH and Pi Management
```bash
# Connect to Pi interactively
./ssh_pi_robust.sh

# Run command on Pi
./ssh_pi_robust.sh "command here"

# Start Pi streamer manually (alternative method)
./ssh_pi_robust.sh "cd /home/ivyspec/ivy_streamer && source venv/bin/activate && python triple_streamer.py"

# System diagnostics
./system_diagnostic.sh
```


## Network Requirements

- Pi streaming on ports 5000, 5001, 5002
- Same network as Raspberry Pi
- ~14 Mbps bandwidth for full resolution
- GStreamer installed on PC

## Features

- **Triple simultaneous streams**: RGB + Left + Right cameras
- **Real-time overlays**: FPS, resolution, timestamp
- **Status monitoring**: Process health checking
- **Flexible display**: Multiple overlay options
- **Pi management**: SSH and remote control tools

## Files in this Repository

- `start_triple_advanced_overlay.sh` - **Complete setup** - Pi streamer + PC receivers (ONE COMMAND)
- `start_triple.sh` - **Smart Pi startup** with automatic cleanup (RECOMMENDED)
- `test_triple_advanced_overlay.sh` - **Advanced receiver** with full telemetry overlays
- `test_triple_overlay.sh` - **Basic receiver** with FPS overlay only
- `test_triple.sh` - **Simple receiver** without overlays (minimal CPU)
- `ssh_pi_robust.sh` - Robust SSH connection script for Pi management
- `system_diagnostic.sh` - Comprehensive system health check
- `requirements.txt` - System dependencies list
- `docs/` - Additional documentation and guides

## Advanced Features

### Real-time Overlays
- **Stream identification**: RGB/Left/Right camera labels
- **Resolution display**: Live resolution information
- **FPS monitoring**: Real-time frames per second
- **Timestamp overlay**: Current date and time
- **Performance stats**: Rendered/dropped frame counts

### Process Monitoring
- **Health checking**: Automatic process status monitoring
- **Error detection**: Failed stream alerts
- **Recovery guidance**: Troubleshooting suggestions
- **Resource usage**: CPU and memory monitoring

### Multiple Display Modes
- **Advanced mode**: Full telemetry (recommended)
- **Basic mode**: FPS only (lower CPU usage)
- **Simple mode**: No overlays (minimal resources)

## Troubleshooting

### No Video Windows Appear
```bash
# 1. Use the smart startup script (handles cleanup automatically)
./start_triple.sh

# 2. If that fails, check ports manually
nc -zv 192.168.1.202 5000 5001 5002

# 3. If ports are closed, try manual cleanup and restart
./ssh_pi_robust.sh "pkill -f triple_streamer.py"
sleep 3
./start_triple.sh

# 4. Verify GStreamer installation
gst-inspect-1.0 --version

# 5. Test individual stream
gst-launch-1.0 tcpclientsrc host=192.168.1.202 port=5000 ! h264parse ! avdec_h264 ! videoconvert ! autovideosink
```

### Poor Video Quality
- **Network**: Use wired Ethernet instead of WiFi
- **Bandwidth**: Reduce Pi streaming resolution/FPS
- **CPU**: Close other applications consuming resources

### Audio Issues
This system streams **video only**. Audio is not supported.

## Related Repositories

- **Pi Streamer**: https://github.com/rbivy/ivy_streamer_pi
- **Complete system** requires both repositories

## System Requirements

- **OS**: Ubuntu 20.04+ or Debian 11+
- **CPU**: Multi-core recommended for 3 simultaneous streams
- **RAM**: 4GB+ recommended
- **Network**: 100 Mbps+ Ethernet (Gigabit preferred)
- **Display**: Multiple monitor setup recommended

## Version History

- **v1.0**: Initial release with advanced overlay support
- Production-tested with multiple simultaneous streams
- Optimized GStreamer pipelines for low latency