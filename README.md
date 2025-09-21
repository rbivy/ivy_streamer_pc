# OAK-D Pro PC Receivers

**Production-ready GStreamer receivers** with advanced real-time overlays for OAK-D Pro triple video streams.

Displays **RGB + Left + Right cameras simultaneously** with telemetry, FPS, timestamps, and monitoring.

## Quick Setup

```bash
# 1. Clone this repository (PC only)
git clone https://github.com/rbivy/ivy_streamer_pc.git
cd ivy_streamer_pc

# 2. Install GStreamer (Ubuntu/Debian)
sudo apt install gstreamer1.0-tools gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-bad

# 3. Make scripts executable
chmod +x *.sh

# 4. Ensure Pi is streaming (from Pi repository)
# Pi should be running: python triple_streamer.py

# 5. Start advanced receivers with overlays
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
# Connect to Pi
./ssh_pi_robust.sh

# Run command on Pi
./ssh_pi_robust.sh "command here"

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
# Check if Pi is streaming
nc -zv <PI_IP> 5000 5001 5002

# Verify GStreamer installation
gst-inspect-1.0 --version

# Test individual stream
gst-launch-1.0 tcpclientsrc host=<PI_IP> port=5000 ! h264parse ! avdec_h264 ! videoconvert ! autovideosink
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