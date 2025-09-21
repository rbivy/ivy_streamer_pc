# OAK-D Pro PC Receivers

**Production-ready GStreamer receivers** with advanced real-time overlays for OAK-D Pro triple video streams.

Displays **RGB + Left + Right cameras simultaneously** with telemetry, FPS, timestamps, and monitoring.

## ⚡ Quick Start (TL;DR)

```bash
# 1. Start Pi streamer (from PC)
sshpass -p "ivyspec" ssh -o StrictHostKeyChecking=no ivyspec@192.168.1.202 \
  "cd /home/ivyspec/ivy_streamer && source venv/bin/activate && python triple_streamer.py" &

# 2. Wait for Pi initialization
sleep 10

# 3. Start PC video receivers
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
# SSH to Pi and start the streamer using the virtual environment
ssh ivyspec@192.168.1.202
cd /home/ivyspec/ivy_streamer
source venv/bin/activate
python triple_streamer.py
```

### Start Video Streaming

**Method 1: Start Pi from PC (Recommended)**
```bash
# From PC - automatically starts Pi streamer via SSH
sshpass -p "ivyspec" ssh -o StrictHostKeyChecking=no ivyspec@192.168.1.202 \
  "cd /home/ivyspec/ivy_streamer && source venv/bin/activate && python triple_streamer.py" &

# Wait 5-10 seconds for Pi to initialize, then start PC receiver
./test_triple_advanced_overlay.sh
```

**Method 2: Manual Steps**
```bash
# 1. First verify Pi connectivity
nc -zv 192.168.1.202 5000 5001 5002

# 2. If ports are closed, start Pi streamer (see Pi Side Setup above)

# 3. Once Pi ports are open, start PC receiver
./test_triple_advanced_overlay.sh
```

## Receiver Scripts

### Advanced Overlays (Recommended)
```bash
./test_triple_advanced_overlay.sh
```
Shows:
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

### SSH and Pi Management
```bash
# Connect to Pi interactively
./ssh_pi_robust.sh

# Run command on Pi
./ssh_pi_robust.sh "command here"

# Start Pi streamer remotely (alternative method)
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
# 1. Check if Pi is streaming (should show "succeeded" for all ports)
nc -zv 192.168.1.202 5000 5001 5002

# 2. If ports are closed, start Pi streamer first
sshpass -p "ivyspec" ssh -o StrictHostKeyChecking=no ivyspec@192.168.1.202 \
  "cd /home/ivyspec/ivy_streamer && source venv/bin/activate && python triple_streamer.py" &

# 3. Wait 10 seconds, then check ports again
sleep 10 && nc -zv 192.168.1.202 5000 5001 5002

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