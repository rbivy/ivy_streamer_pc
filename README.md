# OAK-D Pro Clean Streaming System with Ethernet & Network Monitoring

**Streamlined multi-stream receivers** with clean video feeds optimized for SLAM/computer vision processing. Features **RGB + Left + Right cameras + Depth stream + IMU sensor data + real-time network monitoring**.

Displays **quad video streams without overlays + IMU data + dual interface bandwidth monitoring** over **ethernet connection** for optimal performance (14+ Mbps verified).

## 🌐 Network Configuration

The system uses **ethernet-first architecture** for optimal streaming performance:

- **Pi Ethernet**: 192.168.1.201 (streaming interface)
- **Pi WiFi**: 192.168.1.202 (control/SSH access)
- **PC Ethernet**: 192.168.1.50
- **PC WiFi**: 192.168.1.233

**Bandwidth Verification**: ~14+ Mbps streaming via ethernet, <0.1 Mbps via WiFi (control only)

## ⚡ Quick Start (TL;DR)

```bash
# Install dependencies
pip3 install -r requirements.txt

# Complete setup with clean video + IMU + network monitoring (RECOMMENDED)
./start_quad_with_imu.sh
```


## Quick Setup

### PC Side (This Repository)
```bash
# 1. Clone this repository
git clone https://github.com/rbivy/ivy_streamer_pc.git
cd ivy_streamer_pc

# 2. Install system dependencies (Ubuntu/Debian)
sudo apt install gstreamer1.0-tools gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-bad python3-tk

# 3. Install Python dependencies
pip3 install -r requirements.txt
# OR manually:
pip3 install opencv-python numpy pyzmq msgpack msgpack-numpy open3d

# 4. Make scripts executable
chmod +x *.sh *.py
```

### Pi Side Setup (Required First)
```bash
# Pi repository: https://github.com/rbivy/ivy_streamer_pi
# SSH to Pi and start the streamer using the virtual environment
ssh ivyspec@192.168.1.202
cd /home/ivyspec/ivy_streamer
source venv/bin/activate

# Choose one:
python quad_streamer_with_imu.py              # 4 videos + IMU
```

## Streaming Features

**Video Streams:**
- **RGB**: 1280x720 @ 30fps (H.264, 8Mbps) - Port 5000 *
- **Left Mono**: 1280x720 @ 30fps (H.264, 3Mbps) - Port 5001
- **Right Mono**: 1280x720 @ 30fps (H.264, 3Mbps) - Port 5002
- **Depth**: 1280x720 @ 30fps (JPEG-encoded) - Port 5003

**Note:** *RGB camera uses IMX378 sensor with 1080p native resolution that crops to 720p output. For SLAM applications requiring matched field-of-view, consider this limitation when calibrating stereo pairs.

**IMU Data Stream:**
- **IMU**: Accelerometer + Gyroscope @ 100Hz (UDP JSON) - Port 5004
- **Real-time sensor fusion**: 3-axis acceleration and rotation data
- **High frequency**: 100Hz update rate for precise motion tracking
- **Low latency**: UDP protocol optimized for sensor data

## Starting the System

**Method 1: Complete System (Recommended)**
```bash
# Basic quad + IMU (5 windows)
./start_quad_with_imu.sh
```

**Method 3: Manual Control**
```bash
# Start Pi streamer manually via SSH
./ssh_pi_robust.sh "cd /home/ivyspec/ivy_streamer && source venv/bin/activate && python quad_streamer_with_imu.py" &

# Wait for initialization, then start PC receivers
sleep 18 && ./test_quad_with_imu.sh
```

**Method 4: Individual Components**
```bash
# 1. Verify Pi connectivity (all data streams)
nc -zv 192.168.1.202 5000 5001 5002 5003
# Note: Port 5004 is UDP for IMU

# 2. Start PC receivers only (if Pi already running)
./test_quad_with_imu.sh
```

## Display Windows

### System Display (5 Windows)
```bash
./test_quad_with_imu.sh
```
Shows:
- **4 video windows**: RGB + Left + Right + Depth cameras
- **1 IMU data window**: Real-time sensor display with:
  - **Accelerometer**: 3-axis acceleration in m/s²
  - **Gyroscope**: 3-axis rotation in rad/s and degrees/s
  - **Visual indicators**: ASCII bar graphs for acceleration vectors
  - **Statistics**: Data rate (~100Hz), packet count, timestamps

**Performance**: ~30fps RGB, ~17fps stereo cameras, ~30fps depth, ~100Hz IMU

## IMU Data Features

### Real-time Sensor Display
- **3-axis accelerometer**: Forward/back, left/right, up/down motion
- **3-axis gyroscope**: Pitch, yaw, roll rotation rates
- **Live visualization**: ASCII graphs showing acceleration direction
- **Dual units**: Gyroscope shown in both rad/s and degrees/s
- **High precision**: 4 decimal place accuracy for precise measurements

### GUI Window
- **Dedicated IMU window**: Separate GUI for sensor data visualization
- **Terminal-style display**: Black background with green text
- **Real-time updates**: 50ms refresh rate for smooth data flow
- **Connection status**: Live indication of streaming status

## Utility Scripts

### Pi Streamer Management
```bash
# Stop all Pi streamers
./ssh_pi_robust.sh "pkill -f quad_streamer"

# Check Pi streamer status
./ssh_pi_robust.sh "ps aux | grep quad_streamer"
```

### SSH and Pi Management
```bash
# Connect to Pi interactively
./ssh_pi_robust.sh

# Run command on Pi
./ssh_pi_robust.sh "command here"

# System diagnostics
./system_diagnostic.sh
```

## Network Requirements

- **Pi streaming ports**:
  - 5000-5003: TCP (video streams)
  - 5004: UDP (IMU data)
- **Same network**: PC and Raspberry Pi must be on same network
- **Bandwidth**: ~14 Mbps for video
- **Dependencies**: GStreamer, OpenCV, Python3-tk, Open3D, pyzmq on PC

## Files in this Repository

### Main Scripts
- `start_quad_with_imu.sh` - **Complete setup** - Automated Pi streamer + PC receivers
- `test_quad_with_imu.sh` - **PC receivers only** - 5 windows (RGB + Left + Right + Depth + IMU)

### Data Receivers
- `imu_receiver.py` - **IMU data receiver** - Terminal-based IMU display
- `launch_imu_window.py` - **IMU GUI window** - Graphical IMU data display

### Utilities
- `ssh_pi_robust.sh` - Robust SSH connection script for Pi management
- `system_diagnostic.sh` - Comprehensive system health check
- `requirements.txt` - System dependencies list
- `docs/` - Additional documentation and guides

## Advanced Features

### Video Stream Overlays
- **Stream identification**: RGB/Left/Right/Depth camera labels
- **Resolution display**: Live resolution information (1280x720)
- **FPS monitoring**: Real-time frames per second counters
- **Timestamp overlay**: Current date and time
- **Performance stats**: Rendered/dropped frame counts

### IMU Data Processing
- **JSON protocol**: Structured data format for easy parsing
- **UDP streaming**: Low-latency protocol optimal for sensor data
- **Timestamp sync**: Precise timing information for each reading
- **Error handling**: Robust connection management and recovery

### Process Monitoring
- **Health checking**: Automatic process status monitoring
- **Error detection**: Failed stream alerts with recovery guidance
- **Resource monitoring**: CPU and memory usage tracking
- **Multi-window management**: Coordinated cleanup of all displays

## Troubleshooting

### No Windows Appear
```bash
# 1. Use the automated startup script
./start_quad_with_imu.sh

# 2. Check Pi connectivity
nc -zv 192.168.1.202 5000 5001 5002 5003

# 3. Verify Pi streamer is running
./ssh_pi_robust.sh "ps aux | grep quad_streamer_with_imu"

# 4. Check GStreamer installation
gst-inspect-1.0 --version

# 5. Test individual video stream
gst-launch-1.0 tcpclientsrc host=192.168.1.202 port=5000 ! h264parse ! avdec_h264 ! videoconvert ! autovideosink
```

### IMU Data Issues
```bash
# 1. Test IMU connection
python3 imu_receiver.py

# 2. Check Pi IMU streamer
./ssh_pi_robust.sh "python -c 'import depthai; print(\"DepthAI available\")'"

# 3. Verify Python dependencies
python3 -c "import tkinter, json, socket; print('Dependencies OK')"
```

### Performance Issues
- **Network**: Use wired Ethernet instead of WiFi (14+ Mbps required)
- **CPU**: Close other applications consuming resources
- **Multiple displays**: Consider single monitor if system is slow
- **IMU rate**: 100Hz is optimal; higher rates may cause lag

### Connection Problems
```bash
# Reset all connections
./ssh_pi_robust.sh "pkill -f quad_streamer"
sleep 3
./start_quad_with_imu.sh
```

## System Requirements

### PC Requirements
- **OS**: Ubuntu 20.04+ or Debian 11+
- **CPU**: Multi-core recommended for 7 simultaneous data streams
- **RAM**: 4GB+ recommended
- **Network**: 100 Mbps+ Ethernet (Gigabit preferred)
- **Display**: Multiple monitor setup recommended for best experience
- **Dependencies**: GStreamer, OpenCV, Python3, Tkinter, Open3D, pyzmq

### Pi Requirements
- **DepthAI**: Compatible OAK-D Pro camera
- **Python**: 3.7+ with depthai library
- **Network**: Stable connection to same network as PC

## Related Repositories

- **Pi Streamer**: https://github.com/rbivy/ivy_streamer_pi
- **Complete system** requires both repositories

## Version History

- **v4.0**: Clean streaming system with ethernet optimization (CURRENT)
- **v3.1**: RGB field-of-view optimization and documentation updates
  - Investigated RGB camera scaling limitations (IMX378 sensor constraints)
  - Documented RGB vs mono camera field-of-view differences for SLAM
  - Improved software scaling implementation with OpenCV
- **v3.0**: Quad-stream system with IMU sensor data integration
- **v2.0**: Quad-stream system with depth support
- **v1.0**: Initial triple-stream release
- Production-tested with real-time depth computation, sensor fusion, and 3D reconstruction
- Optimized multithreaded architecture for 4 video + 1 sensor stream

## Technical Details

### Data Flow Architecture
1. **Pi**: OAK-D Pro → `quad_streamer_with_imu.py` → Network (5 streams)
2. **PC**: Network → GStreamer (video) + Python (IMU) → Display windows

### Stream Specifications
- **Video**: H.264 compression, TCP reliable delivery
- **Depth**: JPEG compression, TCP reliable delivery
- **IMU**: JSON format, UDP low-latency delivery
- **Synchronization**: Timestamp-based coordination

### Performance Characteristics
- **Latency**: <100ms for video, <50ms for IMU
- **Reliability**: Automatic reconnection and error recovery
- **Efficiency**: Hardware-accelerated video encoding/decoding
- **Data rates**: ~30 FPS video, ~100 Hz IMU