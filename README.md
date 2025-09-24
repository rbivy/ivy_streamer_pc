# OAK-D Pro Quad Streaming System with IMU & Point Cloud

**Production-ready multi-stream receivers** with advanced real-time overlays for OAK-D Pro quad video streams **+ IMU data + 3D Point Cloud**.

Displays **RGB + Left + Right cameras + Depth stream + IMU sensor data + Point Cloud visualization simultaneously** with telemetry, FPS, timestamps, and 3D rendering.

## ⚡ Quick Start (TL;DR)

```bash
# Install dependencies
pip3 install -r requirements.txt

# Complete setup with all features (RECOMMENDED)
./start_quad_with_imu_pointcloud.sh
```

**OR without Point Cloud:**
```bash
# Basic quad + IMU only
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
python quad_streamer_with_imu_pointcloud.py   # 4 videos + IMU + Point Cloud (NEW!)
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

**Point Cloud Stream (NEW!):**
- **3D Point Cloud**: Real-time XYZ coordinates (ZMQ msgpack) - Port 5005
- **Sparse/Dense modes**: Configurable point density for performance
- **Color integration**: Optional RGB values for each point
- **3D Visualization**: Interactive Open3D rendering with rotation/zoom
- **Statistics**: Live depth distribution, point count, spatial bounds
- **High performance**: ZMQ protocol with msgpack serialization

## Starting the System

**Method 1: Full System with Point Cloud (Recommended)**
```bash
# Complete automated setup - All 7 windows
./start_quad_with_imu_pointcloud.sh
```

**Method 2: Without Point Cloud**
```bash
# Basic quad + IMU (5 windows)
./start_quad_with_imu.sh
```

**Method 3: Manual Control**
```bash
# Start Pi streamer manually via SSH
./ssh_pi_robust.sh "cd /home/ivyspec/ivy_streamer && source venv/bin/activate && python quad_streamer_with_imu_pointcloud.py" &

# Wait for initialization, then start PC receivers
sleep 18 && ./test_quad_with_imu_pointcloud.sh
```

**Method 4: Individual Components**
```bash
# 1. Verify Pi connectivity (all data streams)
nc -zv 192.168.1.202 5000 5001 5002 5003
# Note: Port 5004 is UDP for IMU, Port 5005 is ZMQ for Point Cloud

# 2. Start PC receivers only (if Pi already running)
./test_quad_with_imu_pointcloud.sh  # With Point Cloud
# OR
./test_quad_with_imu.sh              # Without Point Cloud
```

## Display Windows

### Full System Display (7 Windows)
```bash
./test_quad_with_imu_pointcloud.sh
```
Shows:
- **4 video windows**: RGB + Left + Right + Depth cameras
- **1 IMU data window**: Real-time sensor display with:
  - **Accelerometer**: 3-axis acceleration in m/s²
  - **Gyroscope**: 3-axis rotation in rad/s and degrees/s
  - **Visual indicators**: ASCII bar graphs for acceleration vectors
  - **Statistics**: Data rate (~100Hz), packet count, timestamps
- **1 Point Cloud stats window**: Terminal display with:
  - **Point count**: Total number of 3D points
  - **Spatial bounds**: Min/max XYZ coordinates in mm
  - **Depth histogram**: Distribution of depth values
  - **Data rate**: Streaming bandwidth in Mbps
- **1 Point Cloud 3D window**: Interactive Open3D visualization with:
  - **Real-time rendering**: Color-coded depth visualization
  - **Mouse controls**: Rotate, zoom, pan the view
  - **FPS counter**: Rendering performance metrics

**Performance**: ~30fps RGB, ~17fps stereo cameras, ~30fps depth, ~100Hz IMU, ~10-30fps Point Cloud

### Basic System Display (5 Windows)
```bash
./test_quad_with_imu.sh
```
Shows 4 video windows + 1 IMU window (no Point Cloud)

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
  - 5005: TCP/ZMQ (Point Cloud)
- **Same network**: PC and Raspberry Pi must be on same network
- **Bandwidth**: ~14 Mbps for video + ~5-10 Mbps for Point Cloud
- **Dependencies**: GStreamer, OpenCV, Python3-tk, Open3D, pyzmq on PC

## Files in this Repository

### Main Scripts
- `start_quad_with_imu_pointcloud.sh` - **Full setup** - All 7 windows with Point Cloud (NEW!)
- `start_quad_with_imu.sh` - **Basic setup** - 5 windows without Point Cloud
- `test_quad_with_imu_pointcloud.sh` - **Full receivers** - 7 windows including Point Cloud
- `test_quad_with_imu.sh` - **Basic receivers** - 5 windows without Point Cloud

### Data Receivers
- `imu_receiver.py` - **IMU data receiver** - Terminal-based IMU display
- `launch_imu_window.py` - **IMU GUI window** - Graphical IMU data display
- `pointcloud_receiver.py` - **Point Cloud stats** - Terminal statistics display (NEW!)
- `pointcloud_visualizer.py` - **Point Cloud 3D** - Interactive Open3D visualization (NEW!)

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
- **GPU**: Recommended for Point Cloud 3D visualization
- **RAM**: 6GB+ recommended (8GB+ for optimal performance with Point Cloud)
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

- **v4.0**: Point Cloud integration with 3D visualization (CURRENT)
  - Added real-time 3D point cloud streaming via ZMQ
  - Integrated Open3D for interactive 3D visualization
  - Support for sparse/dense point clouds with color
  - Optimized serialization with msgpack for performance
- **v3.1**: RGB field-of-view optimization and documentation updates
  - Investigated RGB camera scaling limitations (IMX378 sensor constraints)
  - Documented RGB vs mono camera field-of-view differences for SLAM
  - Improved software scaling implementation with OpenCV
- **v3.0**: Quad-stream system with IMU sensor data integration
- **v2.0**: Quad-stream system with depth support
- **v1.0**: Initial triple-stream release
- Production-tested with real-time depth computation, sensor fusion, and 3D reconstruction
- Optimized multithreaded architecture for 4 video + 1 sensor + 1 point cloud stream

## Technical Details

### Data Flow Architecture
1. **Pi**: OAK-D Pro → `quad_streamer_with_imu_pointcloud.py` → Network (6 streams)
2. **PC**: Network → GStreamer (video) + Python (IMU/PCL) → Display windows

### Stream Specifications
- **Video**: H.264 compression, TCP reliable delivery
- **Depth**: JPEG compression, TCP reliable delivery
- **IMU**: JSON format, UDP low-latency delivery
- **Point Cloud**: msgpack serialization, ZMQ pub-sub pattern
- **Synchronization**: Timestamp-based coordination

### Performance Characteristics
- **Latency**: <100ms for video, <50ms for IMU, <100ms for Point Cloud
- **Reliability**: Automatic reconnection and error recovery
- **Efficiency**: Hardware-accelerated video encoding/decoding
- **Point Cloud**: On-device generation using Myriad X VPU
- **Data rates**: ~30 FPS video, ~100 Hz IMU, ~10-30 FPS Point Cloud