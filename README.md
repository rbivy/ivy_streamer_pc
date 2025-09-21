# OAK-D Pro Triple Video Streamer

Stream RGB + Stereo (Left + Right) video from Luxonis OAK-D Pro camera connected to Raspberry Pi 5 to PC over Ethernet.

## Architecture

- **Protocol**: H.264 encoded video over TCP sockets
- **Streams**: 3 simultaneous streams (RGB + Left + Right cameras)
- **Ports**: RGB (5000), Left (5001), Right (5002)
- **Latency**: ~50-100ms typical
- **Resolution**: RGB 1920x1080, Mono cameras 1280x720
- **FPS**: Full 30fps all streams with GStreamer receiver
- **Performance**: **GStreamer receiver recommended** for optimal performance

## Setup

### Raspberry Pi 5 Setup

1. **MUST USE VIRTUAL ENVIRONMENT**:
```bash
cd ivy_streamer
source venv/bin/activate  # CRITICAL: Always activate venv first
pip install depthai numpy
```

2. **Connect OAK-D Pro** via USB3

3. **Run triple streamer** (in virtual environment):
```bash
source venv/bin/activate  # CRITICAL: Must activate venv
python triple_streamer.py
```

Options:
- `--host`: Bind address (default: 0.0.0.0)
- `--rgb-port`: RGB port (default: 5000)
- `--left-port`: Left camera port (default: 5001)
- `--right-port`: Right camera port (default: 5002)
- `--rgb-width`: RGB width (default: 1920)
- `--rgb-height`: RGB height (default: 1080)
- `--mono-width`: Mono cameras width (default: 1280)
- `--mono-height`: Mono cameras height (default: 720)
- `--fps`: Frames per second (default: 30)

### PC Setup

#### GStreamer Receiver (RECOMMENDED - Full 30fps all streams)
**No virtual environment needed** - uses system GStreamer:
```bash
# Start all three video streams
./test_triple.sh

# Manual commands for individual streams:
# RGB stream
gst-launch-1.0 tcpclientsrc host=<RASPBERRY_PI_IP> port=5000 ! h264parse ! avdec_h264 ! videoconvert ! autovideosink sync=false

# Left camera stream
gst-launch-1.0 tcpclientsrc host=<RASPBERRY_PI_IP> port=5001 ! h264parse ! avdec_h264 ! videoconvert ! autovideosink sync=false

# Right camera stream
gst-launch-1.0 tcpclientsrc host=<RASPBERRY_PI_IP> port=5002 ! h264parse ! avdec_h264 ! videoconvert ! autovideosink sync=false
```

## Usage Examples

### Basic triple streaming (RECOMMENDED):
```bash
# On Raspberry Pi (MUST use venv)
cd ivy_streamer && source venv/bin/activate
python triple_streamer.py

# On PC (GStreamer - Full 30fps all 3 streams)
./test_triple.sh
```

### Custom resolution for bandwidth optimization:
```bash
# On Raspberry Pi (lower resolution for all cameras)
source venv/bin/activate
python triple_streamer.py --rgb-width 1280 --rgb-height 720 --mono-width 640 --mono-height 480 --fps 15
```

### Individual stream access:
```bash
# View only RGB stream
gst-launch-1.0 tcpclientsrc host=192.168.1.202 port=5000 ! h264parse ! avdec_h264 ! videoconvert ! autovideosink sync=false

# View only Left camera
gst-launch-1.0 tcpclientsrc host=192.168.1.202 port=5001 ! h264parse ! avdec_h264 ! videoconvert ! autovideosink sync=false

# View only Right camera
gst-launch-1.0 tcpclientsrc host=192.168.1.202 port=5002 ! h264parse ! avdec_h264 ! videoconvert ! autovideosink sync=false
```

## Performance Tips

1. **Use Ethernet** connection between Pi and PC for best performance
2. **Adjust resolution/FPS** based on network bandwidth
3. **Monitor CPU usage** on Pi - consider lower resolution if high
4. **Keyframe frequency** is set to 30 (once per second) for quick recovery
5. **All 3 streams run simultaneously** at full 30fps with proper bandwidth

## Troubleshooting

### Quick Diagnostic
```bash
# Run comprehensive system check
./system_diagnostic.sh
```

### Common Issues

#### SSH Connection Problems
```bash
# Use robust SSH script with detailed error checking
./ssh_pi_robust.sh
```

#### GStreamer Issues
```bash
# Use robust receiver with dependency checking
./start_gst_receiver_robust.sh
```

#### "X_LINK_DEVICE_ALREADY_IN_USE" Error
- The script uses DepthAI v3.0 patterns to avoid this
- If error persists, unplug and replug OAK-D Pro

#### High Latency
- Check network connection (use wired Ethernet)
- Reduce resolution or FPS
- Ensure no other heavy network traffic

#### Connection Refused
- Check firewall settings on both devices
- Verify IP address and port
- Ensure streamer is running before receiver

## Automation Scripts

For easier operation, use the provided automation scripts:

### SSH Scripts
```bash
# Interactive SSH to Pi
./ssh_pi.sh

# Run command on Pi
./ssh_pi.sh "command"
```

### Automated Triple Streamer Start
```bash
# Start triple streamer on Pi automatically (with venv, kills existing streamers first)
./start_triple.sh

# Stop all streamers on Pi (Ctrl+C or kill processes)
```

### PC Receiver
```bash
# RECOMMENDED: All 3 streams with GStreamer (Full 30fps each)
./test_triple.sh

# Manual individual stream commands shown in examples above
```

## Network Requirements

- **Bandwidth** (for all 3 streams combined):
  - RGB 1080p @ 30fps: ~8 Mbps
  - Left mono 720p @ 30fps: ~3 Mbps
  - Right mono 720p @ 30fps: ~3 Mbps
  - **Total: ~14 Mbps** for full resolution
- **Latency**: < 10ms recommended
- **Protocols**: TCP ports 5000 (RGB), 5001 (Left), 5002 (Right)

## Clean File Structure (Current - Triple Stream Architecture)

### PC Directory (`/home/ryan/ivy_streamer/`):
```
ivy_streamer/
├── triple_streamer.py             # MAIN: Triple stream generator (RGB + Left + Right)
├── start_triple.sh                # Start triple streamer on Pi remotely
├── test_triple.sh                 # Start all 3 GStreamer receivers on PC
├── ssh_pi_robust.sh               # Robust SSH connection to Pi
├── system_diagnostic.sh           # Comprehensive troubleshooting tool
├── requirements.txt               # Python dependencies
├── Issues_To_Avoid                # Critical lessons learned (KEEP!)
├── README.md                      # Main documentation (updated for triple streams)
└── FUTURE_SELF_GUIDE.md          # Quick reference guide
```

### Pi Directory (`/home/ivyspec/ivy_streamer/`):
```
ivy_streamer/
├── venv/                    # Virtual environment (CRITICAL for Pi)
├── triple_streamer.py      # MAIN: Pi triple camera streamer (RGB + Left + Right)
├── system_diagnostic.sh    # System health check tool
├── Issues_To_Avoid         # Critical lessons learned (KEEP!)
├── README.md              # Documentation copy
└── FUTURE_SELF_GUIDE.md   # Quick reference copy
```

**Architecture Changes:**
- ✅ **Unified triple stream approach** - RGB + Left + Right cameras
- ✅ **3 simultaneous H.264 streams** at full 30fps each
- ✅ **Separate ports** for each camera (5000, 5001, 5002)
- ✅ **Removed all legacy single-stream files**
- ✅ **Clean, production-ready file structure**