# OAK-D Pro Streaming System - Detailed Startup Guide

**For Claude Code Assistant**: This document provides step-by-step instructions for starting the OAK-D Pro streaming system. Follow these exact steps every time to avoid startup issues.

## Prerequisites Check

Before starting, verify these components are in place:

### 1. Network Configuration
```bash
# Verify Pi is reachable via ethernet (streaming interface)
ping -c 3 192.168.1.201

# Verify Pi is reachable via WiFi (SSH/control interface)
ping -c 3 192.168.1.202
```

### 2. SSH Authentication
```bash
# Test SSH connection (should work without password)
ssh -o ConnectTimeout=3 pi "echo 'SSH test successful'"

# If SSH fails, check SSH keys are configured properly
ls -la ~/.ssh/
# Should show: config, pi_key, pi_key.pub, known_hosts
```

### 3. Pi Streamer Software
```bash
# Verify Pi streamer code exists
ssh pi "ls -la /home/ivyspec/ivy_streamer/quad_streamer_with_imu.py"

# Check if virtual environment exists
ssh pi "ls -la /home/ivyspec/ivy_streamer/venv/"
```

### 4. PC Dependencies
```bash
# Check GStreamer installation
which gst-launch-1.0

# Check Python dependencies
python3 -c "import cv2, numpy, json, socket, tkinter; print('All dependencies OK')"

# Make scripts executable
chmod +x *.sh *.py
```

## Startup Methods

### Method 1: Automated Complete System (RECOMMENDED)

**Use this method first** - it handles everything automatically:

```bash
./start_quad_with_imu_optimized.sh
```

**What this does:**
1. Stops any existing Pi streamers
2. Starts Pi streamer via SSH
3. Waits 15 seconds for initialization
4. Verifies all ports are accessible
5. Launches PC receivers (6 windows)

**Expected output:**
- "✓ Pi streamer running"
- "✓ Port 5000: OK (video stream)" (x4 ports)
- 6 windows should open automatically

### Method 2: Manual Step-by-Step (If Method 1 Fails)

If the automated method has issues, run manually:

#### Step A: Stop Existing Processes
```bash
# Stop any existing Pi streamers
ssh pi "pkill -f quad_streamer"

# Stop any existing PC receivers
pkill -f "gst-launch-1.0.*tcpclientsrc"
pkill -f "launch_imu_window.py"
pkill -f "dual_interface_monitor.py"

# Wait for cleanup
sleep 3
```

#### Step B: Start Pi Streamer
```bash
# Start Pi streamer in background
ssh pi "cd /home/ivyspec/ivy_streamer && source venv/bin/activate && python quad_streamer_with_imu.py" &

# Wait for initialization (IMPORTANT - don't skip this!)
sleep 18
```

**Monitor for startup messages:**
- Look for "DeprecationWarning" messages (these are normal)
- Streamer should start without "Address already in use" errors

#### Step C: Verify Pi Streamer Status
```bash
# Check if streamer process is running
ssh pi "ps aux | grep quad_streamer | grep -v grep"

# Test video ports (should show "Connection succeeded")
for port in 5000 5001 5002 5003; do
    echo -n "Port $port: "
    nc -zv 192.168.1.201 $port
done
```

#### Step D: Start PC Receivers
```bash
# Start all PC receivers (6 windows)
./test_quad_with_imu.sh
```

**Expected windows:**
1. RGB camera (1920x1080 → 1280x720)
2. Left stereo camera (1280x720)
3. Right stereo camera (1280x720)
4. Raw depth stream (1280x720, colorized for display)
5. IMU data (GUI window with sensor readings)
6. Network monitor (bandwidth and FPS stats)

### Method 3: Individual Component Testing

If you need to test components separately:

#### Test Individual Video Streams
```bash
# RGB stream only
gst-launch-1.0 tcpclientsrc host=192.168.1.201 port=5000 ! h264parse ! avdec_h264 ! videoconvert ! autovideosink

# Left camera only
gst-launch-1.0 tcpclientsrc host=192.168.1.201 port=5001 ! h264parse ! avdec_h264 ! videoconvert ! autovideosink

# Test depth stream
python3 -c "
import socket, cv2, numpy as np, struct
sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
sock.connect(('192.168.1.201', 5003))
print('Connected to depth stream')
sock.close()
"
```

#### Test IMU Data
```bash
# Test IMU receiver directly
python3 imu_receiver.py
# Should show live IMU data at ~100Hz
```

#### Test Network Monitor
```bash
# Test network monitoring
python3 dual_interface_monitor.py
# Should show bandwidth stats for ethernet/WiFi
```

## Troubleshooting Common Issues

### Issue 1: "Address already in use"
```bash
# Solution: Stop existing streamers first
ssh pi "pkill -f quad_streamer"
sleep 3
# Then restart
```

### Issue 2: SSH Connection Failed
```bash
# Check SSH config
cat ~/.ssh/config | grep -A 10 "Host pi"

# Test basic SSH
ssh -v pi "echo test" 2>&1 | grep -i error

# If needed, regenerate SSH keys (advanced)
ssh-keygen -f ~/.ssh/pi_key -N ""
ssh-copy-id -i ~/.ssh/pi_key.pub ivyspec@192.168.1.202
```

### Issue 3: No Video Windows Appear
```bash
# Check Pi connectivity first
nc -zv 192.168.1.201 5000 5001 5002 5003

# Check GStreamer
gst-inspect-1.0 --version

# Test simple video pipeline
gst-launch-1.0 videotestsrc ! autovideosink
```

### Issue 4: IMU Window Not Opening
```bash
# Check Python Tkinter
python3 -c "import tkinter; print('Tkinter OK')"

# Test IMU connection directly
python3 -c "
import socket
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sock.bind(('', 5004))
sock.settimeout(5)
try:
    data, addr = sock.recvfrom(1024)
    print(f'Received IMU data from {addr}')
except:
    print('No IMU data received')
sock.close()
"
```

### Issue 5: Poor Performance/Lag
```bash
# Check network bandwidth
python3 dual_interface_monitor.py
# Should show ~14 Mbps via ethernet, minimal via WiFi

# Reduce window count for testing
# Comment out some receivers in test_quad_with_imu.sh
```

## Stopping the System

### Clean Shutdown
```bash
# Press Ctrl+C in the terminal running the receivers
# This triggers automatic cleanup of both PC and Pi processes
```

### Force Stop All Processes
```bash
# Stop PC receivers
pkill -f "gst-launch-1.0.*tcpclientsrc"
pkill -f "launch_imu_window.py"
pkill -f "dual_interface_monitor.py"

# Stop Pi streamers
ssh pi "pkill -f quad_streamer"
```

## System Status Verification

Use this checklist to verify everything is working:

- [ ] Pi pingable at 192.168.1.201 (ethernet)
- [ ] Pi pingable at 192.168.1.202 (WiFi)
- [ ] SSH to Pi works without password
- [ ] Pi streamer process running
- [ ] Ports 5000-5003 accessible via TCP
- [ ] 6 windows opened on PC
- [ ] RGB stream showing 1920x1080→1280x720 video
- [ ] Left/Right streams showing 1280x720 video
- [ ] Depth stream showing colorized depth data
- [ ] IMU window showing ~100Hz sensor data
- [ ] Network monitor showing ~14 Mbps ethernet usage

## Performance Expectations

When everything is working correctly:

- **Video Quality**: Clean, smooth 30 FPS on all video streams
- **IMU Data**: ~100 Hz update rate with timestamps
- **Latency**: <100ms end-to-end for video, <50ms for IMU
- **Bandwidth**: ~14-15 Mbps total via ethernet
- **CPU Usage**: ~30-35% on Pi, ~10-15% on PC
- **No dropped frames** in network monitor

## Notes for Claude Code Assistant

- **Always wait 15-18 seconds** after starting Pi streamer before starting PC receivers
- **Check SSH connectivity first** - most issues stem from SSH problems
- **Use Method 1 (automated) first**, fall back to Method 2 if needed
- **The system requires both Pi and PC components** - this repo is PC-side only
- **6 windows should open** - if fewer open, something failed
- **Raw depth stream is SLAM-ready** - 16-bit uncompressed depth values
- **IMU data is 100Hz, not 200Hz** as some older docs indicated