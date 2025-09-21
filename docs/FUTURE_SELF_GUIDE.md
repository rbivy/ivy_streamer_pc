# Future Self Guide - OAK-D Pro PC Receivers

## CRITICAL INFORMATION - PC-ONLY GSTREAMER ARCHITECTURE

### Pi Connection Details
- **IP Address**: 192.168.1.202
- **Username**: ivyspec
- **Password**: ivyspec
- **SSH Port**: 22 (default)

### IMPORTANT: PC-ONLY ARCHITECTURE

This repository is now **PC-side only** using **GStreamer** - no Python virtual environment needed on PC!

#### PC Side (This Repository)
```bash
# NO virtual environment needed! Uses system GStreamer
sudo apt install gstreamer1.0-tools gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-bad

# One command startup
./start_quad_advanced_overlay.sh
```

#### Pi Side (Separate Repository)
```bash
# Pi still needs virtual environment for Python streaming
cd /home/ivyspec/ivy_streamer
source venv/bin/activate
python quad_streamer.py
```

## Quick Start Commands - CURRENT ARCHITECTURE

### 1. Complete System (One Command)
```bash
# Handles Pi startup + PC receivers automatically
./start_quad_advanced_overlay.sh
```

### 2. Manual Steps
```bash
# Step 1: Start Pi streamer with cleanup
./start_quad.sh

# Step 2: Start PC receivers
./test_quad_advanced_overlay.sh
```

### 3. Individual Stream Access
```bash
# RGB stream (1280x720 @ 30fps)
gst-launch-1.0 tcpclientsrc host=192.168.1.202 port=5000 ! h264parse ! avdec_h264 ! videoconvert ! autovideosink sync=false

# Left camera (1280x720 @ 30fps)
gst-launch-1.0 tcpclientsrc host=192.168.1.202 port=5001 ! h264parse ! avdec_h264 ! videoconvert ! autovideosink sync=false

# Right camera (1280x720 @ 30fps)
gst-launch-1.0 tcpclientsrc host=192.168.1.202 port=5002 ! h264parse ! avdec_h264 ! videoconvert ! autovideosink sync=false

# Depth stream (1280x720 @ 30fps)
# Handled by Python OpenCV receiver in the main script
```

## Troubleshooting Common Issues

### 1. "Connection refused" on ports 5000/5001/5002/5003
```bash
# Use the smart startup script (handles cleanup automatically)
./start_quad.sh

# Manual check if needed
nc -zv 192.168.1.202 5000 5001 5002 5003
```

### 2. "No video windows appear"
```bash
# Complete automated setup
./start_quad_advanced_overlay.sh

# Verify GStreamer installation
gst-inspect-1.0 --version
```

### 3. SSH connection issues
```bash
# Test connectivity
ping -c 1 192.168.1.202

# Interactive SSH session
./ssh_pi_robust.sh

# Run command on Pi
./ssh_pi_robust.sh "command here"
```

## File Structure Reference

```
ivy_streamer/ (PC SIDE - THIS REPO)
├── start_quad_advanced_overlay.sh    # Complete one-command setup
├── start_quad.sh                     # Smart Pi startup with cleanup
├── test_quad_advanced_overlay.sh     # PC receivers with overlays and depth
├── ssh_pi_robust.sh                  # Robust SSH connection
├── system_diagnostic.sh              # System diagnostics
├── requirements.txt                  # GStreamer system packages
├── README.md                         # Main documentation
└── docs/                            # Additional guides
```

## Current Working Configuration

- **PC**: GStreamer receivers (no Python needed)
- **Pi**: Python streamers with DepthAI (separate repository)
- **Camera**: OAK-D Pro (USB 3.0 connected to Pi)
- **Streaming**: H.264 over TCP ports 5000, 5001, 5002, 5003
- **Resolution**:
  - RGB: 1280x720 @ 30fps
  - Left/Right: 1280x720 @ 30fps
  - Depth: 1280x720 @ 30fps (JPEG-encoded)
- **Network**: Local ethernet/WiFi (same subnet required)

## Performance Comparison

**GStreamer Receivers (CURRENT - RECOMMENDED)**:
- Full 30fps at target resolutions
- Zero dropped frames
- Hardware-accelerated decoding
- No virtual environment needed
- System integration

**Legacy Python Receivers (DEPRECATED)**:
- ~20fps with frame drops
- Software-only decoding
- Required virtual environment
- Higher CPU usage

## Emergency Commands

If everything breaks:

```bash
# Kill all Pi streamers
./ssh_pi_robust.sh "pkill -f quad_streamer.py"

# Complete restart
./start_quad_advanced_overlay.sh

# System diagnostics
./system_diagnostic.sh

# Manual Pi check
./ssh_pi_robust.sh "lsusb | grep Movidius"  # Check camera
nc -zv 192.168.1.202 5000 5001 5002 5003    # Check ports

# Force kill Pi processes if needed
./ssh_pi_robust.sh "sudo fuser -k 5000/tcp 5001/tcp 5002/tcp 5003/tcp"
```

## Repository Architecture

### This Repository (PC Receivers)
- **Purpose**: GStreamer-based video receivers
- **Language**: Shell scripts + GStreamer
- **Dependencies**: System GStreamer packages
- **No Python virtual environment needed**

### Pi Repository (Separate)
- **Purpose**: DepthAI Python streamers
- **Language**: Python + DepthAI
- **Dependencies**: Python virtual environment required
- **Location**: https://github.com/rbivy/ivy_streamer_pi

## Enhanced Features - Version 2.0

### Automatic Process Cleanup
- **Window Closure Detection**: Closing any video window automatically stops Pi processes
- **Comprehensive Cleanup**: Kills both PC receivers and Pi streamers
- **No Orphaned Processes**: Prevents future connection issues

### Uniform 720p Resolution
- **All 4 streams at 1280x720**: Optimized for SLAM and odometry applications
- **Consistent Quality**: RGB, Left, Right, and Depth all at same resolution
- **Reduced Bandwidth**: ~14 Mbps total for 4 streams

### Advanced Monitoring
- **Real-time Overlays**: FPS counters, timestamps, stream identification
- **Process Health**: Background monitoring with automatic recovery
- **Enhanced Logs**: Detailed startup and cleanup messaging

## Remember: NO PYTHON VIRTUAL ENVIRONMENT ON PC SIDE

This repository now uses **system GStreamer only**. The PC side has been converted from Python to pure GStreamer for better performance and simpler setup.

Only the Pi side (separate repository) still requires Python virtual environment for the DepthAI streaming code.