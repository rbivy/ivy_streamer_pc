# Future Self Guide - OAK-D Pro Triple Video Streamer

## CRITICAL INFORMATION FOR FUTURE USE - TRIPLE STREAM ARCHITECTURE

### Pi Connection Details
- **IP Address**: 192.168.1.202
- **Username**: ivyspec
- **Password**: ivyspec
- **SSH Port**: 22 (default)

### MANDATORY: ALWAYS USE VIRTUAL ENVIRONMENTS

#### On Raspberry Pi
```bash
# ALWAYS activate Pi's venv first
cd /home/ivyspec/ivy_streamer
source venv/bin/activate
```

#### On PC
```bash
# ALWAYS activate PC's venv first
cd /home/ryan/ivy_streamer
source venv/bin/activate
```

**WARNING**: Never run the code without activating the virtual environments. This prevents dependency conflicts and ensures consistent behavior.

## Quick Start Commands - TRIPLE STREAM ARCHITECTURE

### 1. Connect to Pi (Automated)
```bash
# Interactive SSH
./ssh_pi.sh

# Run single command
./ssh_pi.sh "command here"
```

### 2. Start Triple Streaming (One Command)
```bash
# Start triple streamer on Pi automatically (RGB + Left + Right cameras)
./start_triple.sh
```

### 3. Start PC Receivers (RECOMMENDED)

#### All 3 Streams Simultaneously (Full 30fps each)
```bash
# Opens 3 video windows: RGB, Left Camera, Right Camera
./test_triple.sh
```

#### Individual Stream Access
```bash
# RGB stream only (color, 1920x1080)
gst-launch-1.0 tcpclientsrc host=192.168.1.202 port=5000 ! h264parse ! avdec_h264 ! videoconvert ! autovideosink sync=false

# Left camera only (mono, 1280x720)
gst-launch-1.0 tcpclientsrc host=192.168.1.202 port=5001 ! h264parse ! avdec_h264 ! videoconvert ! autovideosink sync=false

# Right camera only (mono, 1280x720)
gst-launch-1.0 tcpclientsrc host=192.168.1.202 port=5002 ! h264parse ! avdec_h264 ! videoconvert ! autovideosink sync=false
```

## Manual Pi Connection Steps

If automation scripts fail:

1. **SSH to Pi**:
   ```bash
   sshpass -p "ivyspec" ssh ivyspec@192.168.1.202
   ```

2. **Navigate and activate venv**:
   ```bash
   cd ivy_streamer
   source venv/bin/activate
   ```

3. **Start triple streamer**:
   ```bash
   python triple_streamer.py
   ```

## Troubleshooting Common Issues

### 1. "X_LINK_DEVICE_ALREADY_IN_USE" Error
This was fixed by implementing proper DepthAI v3.0 patterns. If it occurs:
- The triple_streamer.py follows correct v3.0 API (no explicit device creation)
- Uses context manager pattern with `with pipeline:`
- Creates queues BEFORE `pipeline.start()`

### 2. "No available devices" Error
Fixed by setting proper udev rules:
```bash
# These commands were run and should persist:
./ssh_pi.sh "sudo usermod -a -G plugdev ivyspec"
./ssh_pi.sh "echo 'SUBSYSTEM==\"usb\", ATTRS{idVendor}==\"03e7\", MODE=\"0666\"' | sudo tee /etc/udev/rules.d/80-movidius.rules"
./ssh_pi.sh "sudo udevadm control --reload-rules && sudo udevadm trigger"
```

### 3. Connection Refused on Ports
- Check if triple streamer is running: `./ssh_pi.sh "ps aux | grep triple_streamer"`
- Test ports:
  - `nc -zv 192.168.1.202 5000` (RGB)
  - `nc -zv 192.168.1.202 5001` (Left)
  - `nc -zv 192.168.1.202 5002` (Right)
- Restart streamer: `./start_triple.sh`

### 4. Virtual Environment Issues
If venv is corrupted:

**On Pi**:
```bash
./ssh_pi.sh "cd ivy_streamer && python3 -m venv venv && source venv/bin/activate && pip install depthai numpy"
```

**On PC**:
```bash
cd ivy_streamer
python3 -m venv venv
source venv/bin/activate
pip install opencv-python av numpy
```

## File Structure Reference

```
ivy_streamer/
├── venv/                    # Virtual environment (CRITICAL - always use)
├── streamer_v3.py          # Pi streamer (DepthAI v3.0 compliant)
├── pc_receiver.py          # PC receiver
├── ssh_pi.sh              # Automated SSH script
├── start_streamer.sh      # Automated streamer startup
├── requirements.txt       # Dependencies
├── README.md             # Basic usage
├── DOCUMENTATION.md      # Detailed docs
└── FUTURE_SELF_GUIDE.md  # This file
```

## Key Learning Points

1. **DepthAI v3.0 API Changes**: The original code used v2.x patterns that caused device lock errors. Fixed version uses:
   - `pipeline.create(dai.node.Camera).build()` (not manual camera creation)
   - `pipeline.start()` without explicit device
   - Context manager: `with pipeline:`
   - Queue creation before pipeline start

2. **Device Permissions**: OAK-D Pro requires proper udev rules for non-root access

3. **Virtual Environments**: Critical for preventing dependency conflicts between system packages and project requirements

4. **Automation**: SSH password authentication automated with sshpass for seamless operation

## Current Working Configuration

- **Pi**: Raspberry Pi 5 at 192.168.1.202
- **Camera**: OAK-D Pro (USB 3.0 connected)
- **Streaming**: H.264 over TCP port 5000
- **Resolution**: Default 1920x1080 @ 30fps (configurable)
- **Network**: Local ethernet/WiFi (same subnet required)

## Emergency Commands

If everything breaks:

1. **Kill all processes**:
   ```bash
   ./stop_streamer.sh
   ```

2. **Restart from scratch**:
   ```bash
   ./start_streamer.sh  # Automatically kills existing streamers first

   # RECOMMENDED: GStreamer receiver (Full 30fps)
   gst-launch-1.0 tcpclientsrc host=192.168.1.202 port=5000 ! h264parse ! avdec_h264 ! videoconvert ! autovideosink sync=false

   # OR Legacy: Python receiver (~20fps)
   source venv/bin/activate && python pc_receiver.py 192.168.1.202
   ```

3. **Check system status**:
   ```bash
   ./ssh_pi.sh "lsusb | grep Movidius"  # Check camera
   nc -zv 192.168.1.202 5000            # Check port
   ```

## Performance Comparison

**GStreamer Receiver (RECOMMENDED)**:
- Full 30fps at 1920x1080
- Zero dropped frames
- No decode errors
- Hardware-accelerated decoding
- No virtual environment needed

**Python Receiver (Legacy)**:
- ~20fps at 1920x1080
- Frame drops and decode errors
- Software decoding only
- Requires virtual environment

## Remember: VIRTUAL ENVIRONMENTS ARE NOT OPTIONAL (for Python components)

Pi streamer and Python receiver must be run with the appropriate virtual environment activated. GStreamer receiver uses system libraries and doesn't need venv.