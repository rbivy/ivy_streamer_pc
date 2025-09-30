# OAK-D Pro Streaming System - Software Architecture v6.0 (SLAM-Optimized)

## System Overview

The system consists of two main components:
1. **Raspberry Pi 5** (Data Source/Streamer)
2. **PC** (Data Receiver/Display)

Connected via dual network interfaces (Ethernet for streaming, WiFi for control).

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                              RASPBERRY PI 5                                      │
│                                                                                  │
│  ┌─────────────┐                                                               │
│  │   OAK-D     │                                                               │
│  │   PRO       │                                                               │
│  │  CAMERA     │                                                               │
│  └──────┬──────┘                                                               │
│         │ USB 3.0                                                              │
│         ▼                                                                      │
│  ┌──────────────────────────────────────────────────────────────────┐        │
│  │                     DEPTHAI PIPELINE                             │        │
│  │                                                                   │        │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐       │        │
│  │  │   RGB    │  │  LEFT    │  │  RIGHT   │  │   IMU    │       │        │
│  │  │  Camera  │  │  Camera  │  │  Camera  │  │  Sensor  │       │        │
│  │  │1920x1080 │  │1280x720  │  │1280x720  │  │  200Hz   │       │        │
│  │  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘       │        │
│  │       │             │             │             │               │        │
│  │       ▼             ▼             ▼             │               │        │
│  │  ┌──────────────────────────────────┐          │               │        │
│  │  │     STEREO DEPTH ENGINE          │          │               │        │
│  │  │   (Left + Right → Depth Map)     │          │               │        │
│  │  └────────────┬─────────────────────┘          │               │        │
│  │               │                                 │               │        │
│  │       ┌───────▼───────┐                       │               │        │
│  │       │  DEPTH MAP    │                       │               │        │
│  │       │   1280x720    │                       │               │        │
│  │       └───────┬───────┘                       │               │        │
│  │               │                                 │               │        │
│  └───────────────┼─────────────────────────────────┼───────────────┘        │
│                  │                                 │                          │
│         ┌────────▼────────┐                       │                          │
│         │  RAW 16-BIT     │                       │                          │
│         │  DEPTH DATA     │                       │                          │
│         │ (SLAM-READY)    │                       │                          │
│         └────────┬────────┘                       │                          │
│                  │                                 │                          │
│  ┌───────────────▼─────────────────────────────────▼───────────────┐        │
│  │              quad_streamer_with_imu.py                          │        │
│  │                                                                  │        │
│  │  ┌─────────────────────────────────────────────────────────┐   │        │
│  │  │                  VIDEO ENCODING                          │   │        │
│  │  │                                                          │   │        │
│  │  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌────────┐ │   │        │
│  │  │  │   RGB    │  │  LEFT    │  │  RIGHT   │  │ DEPTH  │ │   │        │
│  │  │  │H.264HIGH │  │H.264HIGH │  │H.264HIGH │  │RAW16BIT│ │   │        │
│  │  │  │ Encoder  │  │ Encoder  │  │ Encoder  │  │Compress│ │   │        │
│  │  │  │ 10 Mbps  │  │ 4 Mbps   │  │ 4 Mbps   │  │        │ │   │        │
│  │  │  └────┬─────┘  └────┬─────┘  └────┬─────┘  └───┬────┘ │   │        │
│  │  └───────┼──────────────┼──────────────┼───────────┼──────┘   │        │
│  │          │              │              │           │           │        │
│  │  ┌───────▼──────────────▼──────────────▼───────────▼────────┐ │        │
│  │  │              TCP SERVER SOCKETS                           │ │        │
│  │  │                                                           │ │        │
│  │  │  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐    │ │        │
│  │  │  │Port 5000│  │Port 5001│  │Port 5002│  │Port 5003│    │ │        │
│  │  │  │   RGB   │  │  LEFT   │  │  RIGHT  │  │  DEPTH  │    │ │        │
│  │  │  └────┬────┘  └────┬────┘  └────┬────┘  └────┬────┘    │ │        │
│  │  └───────┼─────────────┼─────────────┼──────────┼──────────┘ │        │
│  │          │             │             │          │             │        │
│  │  ┌───────────────────────────────────────────────────────┐   │        │
│  │  │                IMU DATA PROCESSING                     │   │        │
│  │  │                                                        │   │        │
│  │  │  ┌─────────────┐  ┌──────────────┐  ┌─────────────┐ │   │        │
│  │  │  │Accelerometer│  │  Gyroscope   │  │ Magnetometer│ │   │        │
│  │  │  │   3-axis    │  │    3-axis    │  │   3-axis    │ │   │        │
│  │  │  └──────┬──────┘  └───────┬──────┘  └──────┬──────┘ │   │        │
│  │  │         └──────────────┬───┴─────────────────┘        │   │        │
│  │  │                        ▼                               │   │        │
│  │  │               ┌─────────────────┐                     │   │        │
│  │  │               │  JSON Encoder   │                     │   │        │
│  │  │               │   @ 100 Hz      │                     │   │        │
│  │  │               └────────┬────────┘                     │   │        │
│  │  │                        ▼                               │   │        │
│  │  │               ┌─────────────────┐                     │   │        │
│  │  │               │ UDP Socket      │                     │   │        │
│  │  │               │ Port 5004       │                     │   │        │
│  │  │               └────────┬────────┘                     │   │        │
│  │  └────────────────────────┼───────────────────────────────┘   │        │
│  │                            │                                    │        │
│  │  ┌──────────────────────────────────────────────────────────┐ │        │
│  │  │              CONNECTION MANAGER                           │ │        │
│  │  │                                                           │ │        │
│  │  │  • Multi-client support per stream                       │ │        │
│  │  │  • Connection pooling and cleanup                        │ │        │
│  │  │  • FPS telemetry (14.2fps RGB, 7.3fps stereo)          │ │        │
│  │  │  • Bandwidth management (~14-15 Mbps total)             │ │        │
│  │  └──────────────────────────────────────────────────────────┘ │        │
│  └──────────────────────────────────────────────────────────────────┘        │
│                                                                                │
└────────────────────────┬───────────────────┬───────────────────────────────────┘
                         │                   │
                ETHERNET │                   │ UDP
           192.168.1.201 │                   │ (IMU)
                    TCP  │                   │
                         ▼                   ▼
    ┌────────────────────────────────────────────────────────────────────────┐
    │                                                                         │
    ├─────────────────────────────────────────────────────────────────────────┤
    │                                PC                                       │
    │                                                                         │
    │  ┌──────────────────────────────────────────────────────────────────┐ │
    │  │                    test_quad_with_imu.sh                         │ │
    │  │                                                                   │ │
    │  │  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐           │ │
    │  │  │  RGB    │  │  LEFT   │  │  RIGHT  │  │  DEPTH  │           │ │
    │  │  │Receiver │  │Receiver │  │Receiver │  │Receiver │           │ │
    │  │  └────┬────┘  └────┬────┘  └────┬────┘  └────┬────┘           │ │
    │  │       │             │             │            │                 │ │
    │  │  ┌────▼─────────────▼─────────────▼────────────▼──────┐        │ │
    │  │  │           GSTREAMER PIPELINES                       │        │ │
    │  │  │                                                      │        │ │
    │  │  │  ┌──────────────────────────────────────────┐      │        │ │
    │  │  │  │ RGB Pipeline (Port 5000)                 │      │        │ │
    │  │  │  │                                           │      │        │ │
    │  │  │  │ tcpclientsrc → h264parse → avdec_h264   │      │        │ │
    │  │  │  │     ↓                                    │      │        │ │
    │  │  │  │ videoconvert → videoscale               │      │        │ │
    │  │  │  │     ↓                                    │      │        │ │
    │  │  │  │ capsfilter (1280x720@30fps)            │      │        │ │
    │  │  │  │     ↓                                    │      │        │ │
    │  │  │  │ autovideosink (XvImageSink)            │      │        │ │
    │  │  │  └──────────────────────────────────────────┘      │        │ │
    │  │  │                                                      │        │ │
    │  │  │  ┌──────────────────────────────────────────┐      │        │ │
    │  │  │  │ LEFT/RIGHT Pipeline (Ports 5001/5002)    │      │        │ │
    │  │  │  │                                           │      │        │ │
    │  │  │  │ tcpclientsrc → h264parse → avdec_h264   │      │        │ │
    │  │  │  │     ↓                                    │      │        │ │
    │  │  │  │ videoconvert → capsfilter (30fps)      │      │        │ │
    │  │  │  │     ↓                                    │      │        │ │
    │  │  │  │ autovideosink                           │      │        │ │
    │  │  │  └──────────────────────────────────────────┘      │        │ │
    │  │  └───────────────────────────────────────────────────────┘      │ │
    │  │                                                                   │ │
    │  │  ┌──────────────────────────────────────────────────────────┐   │ │
    │  │  │              DEPTH RECEIVER (Python/OpenCV)               │   │ │
    │  │  │                                                           │   │ │
    │  │  │  TCP Socket → JPEG Decode → Colormap → Display Window   │   │ │
    │  │  └──────────────────────────────────────────────────────────┘   │ │
    │  └──────────────────────────────────────────────────────────────────┘ │
    │                                                                         │
    │  ┌──────────────────────────────────────────────────────────────────┐ │
    │  │                    imu_receiver.py                               │ │
    │  │                                                                   │ │
    │  │  ┌─────────────┐  ┌────────────────┐  ┌──────────────────┐    │ │
    │  │  │ UDP Socket  │→ │  JSON Decoder  │→ │  Data Processing │    │ │
    │  │  │ Port 5004   │  │   @ 100 Hz     │  │  & Visualization │    │ │
    │  │  └─────────────┘  └────────────────┘  └──────────────────┘    │ │
    │  │                                                                   │ │
    │  │  ┌──────────────────────────────────────────────────────────┐   │ │
    │  │  │                 IMU DATA DISPLAY                          │   │ │
    │  │  │                                                           │   │ │
    │  │  │  • Accelerometer: X/Y/Z in m/s²                         │   │ │
    │  │  │  • Gyroscope: X/Y/Z in rad/s and deg/s                 │   │ │
    │  │  │  • ASCII bar graphs for vector visualization           │   │ │
    │  │  │  • Update rate: 50ms (20 FPS display)                  │   │ │
    │  │  └──────────────────────────────────────────────────────────┘   │ │
    │  └──────────────────────────────────────────────────────────────────┘ │
    │                                                                         │
    │  ┌──────────────────────────────────────────────────────────────────┐ │
    │  │              dual_interface_monitor.py                           │ │
    │  │                                                                   │ │
    │  │  ┌──────────────────────────────────────────────────────────┐   │ │
    │  │  │              NETWORK MONITORING                           │   │ │
    │  │  │                                                           │   │ │
    │  │  │  • /proc/net/dev parsing for bandwidth                  │   │ │
    │  │  │  • Interface statistics (eno2: Ethernet, wlo1: WiFi)    │   │ │
    │  │  │  • 2-second sampling intervals                         │   │ │
    │  │  │  • Historical data (15 samples rolling window)         │   │ │
    │  │  └──────────────────────────────────────────────────────────┘   │ │
    │  │                                                                   │ │
    │  │  ┌──────────────────────────────────────────────────────────┐   │ │
    │  │  │           FPS MONITORING (AGGRESSIVE MODE)               │   │ │
    │  │  │                                                           │   │ │
    │  │  │  ┌────────────────────────────────────────────┐         │   │ │
    │  │  │  │ Per-Stream FPS Monitor Thread              │         │   │ │
    │  │  │  │                                             │         │   │ │
    │  │  │  │ 1. TCP Connect to stream port            │         │   │ │
    │  │  │  │ 2. Read 8KB chunks aggressively          │         │   │ │
    │  │  │  │ 3. Search for frame markers:             │         │   │ │
    │  │  │  │    - H.264: NAL units (0x00000001)      │         │   │ │
    │  │  │  │    - JPEG: SOI markers (0xFFD8)         │         │   │ │
    │  │  │  │ 4. Count frames per second              │         │   │ │
    │  │  │  │ 5. Calculate rolling average (10 samples)│         │   │ │
    │  │  │  │ 6. Track bandwidth consumption          │         │   │ │
    │  │  │  └────────────────────────────────────────────┘         │   │ │
    │  │  │                                                           │   │ │
    │  │  │  Benefits:                                              │   │ │
    │  │  │  • Reduces video latency (buffer draining)             │   │ │
    │  │  │  • Improves frame quality (prevents stale frames)      │   │ │
    │  │  │  • Provides real-time FPS metrics                      │   │ │
    │  │  └──────────────────────────────────────────────────────────┘   │ │
    │  │                                                                   │ │
    │  │  ┌──────────────────────────────────────────────────────────┐   │ │
    │  │  │                 DISPLAY OUTPUT                            │   │ │
    │  │  │                                                           │   │ │
    │  │  │  • Network bandwidth per interface                       │   │ │
    │  │  │  • Per-stream FPS (current/avg/max)                     │   │ │
    │  │  │  • Total frame counts                                   │   │ │
    │  │  │  • Monitoring overhead bandwidth                        │   │ │
    │  │  │  • Active interface detection                           │   │ │
    │  │  └──────────────────────────────────────────────────────────┘   │ │
    │  └──────────────────────────────────────────────────────────────────┘ │
    │                                                                         │
    │  ┌──────────────────────────────────────────────────────────────────┐ │
    │  │                    DISPLAY WINDOWS                               │ │
    │  │                                                                   │ │
    │  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐         │ │
    │  │  │   RGB    │ │   LEFT   │ │  RIGHT   │ │  DEPTH   │         │ │
    │  │  │ 1280x720 │ │ 1280x720 │ │ 1280x720 │ │ 1280x720 │         │ │
    │  │  │  Window  │ │  Window  │ │  Window  │ │  Window  │         │ │
    │  │  └──────────┘ └──────────┘ └──────────┘ └──────────┘         │ │
    │  │                                                                   │ │
    │  │  ┌────────────────────┐  ┌─────────────────────────┐          │ │
    │  │  │    IMU Data        │  │  Network/FPS Monitor   │          │ │
    │  │  │  Terminal Window   │  │    Statistics Window   │          │ │
    │  │  └────────────────────┘  └─────────────────────────┘          │ │
    │  └──────────────────────────────────────────────────────────────────┘ │
    │                                                                         │
    └─────────────────────────────────────────────────────────────────────────┘
```

## Data Flow Summary

### Video Pipeline (Per Stream)

1. **Camera Capture** (OAK-D Pro)
   - RGB: 4K sensor → 1920x1080 output
   - Mono: 1280x720 native resolution
   - Hardware ISP processing

2. **DepthAI Processing** (On-camera)
   - Stereo depth computation
   - IMU data fusion
   - Frame synchronization

3. **Video Encoding** (Pi CPU)
   - H.264 HIGH profile encoding (SLAM-optimized)
   - Bitrate control (10Mbps RGB, 4Mbps mono)
   - Keyframe insertion every 15 frames

4. **Network Transmission** (TCP)
   - Per-client connection handling
   - Non-blocking socket operations
   - Buffer management

5. **Video Decoding** (PC)
   - GStreamer hardware-accelerated decode
   - Format conversion (YUV → RGB)
   - Frame rate limiting (30 FPS cap)

6. **Display Rendering** (PC GPU)
   - XvImageSink for optimal performance
   - Double buffering
   - VSync alignment

### IMU Data Pipeline

1. **Sensor Sampling** (OAK-D Pro)
   - 200Hz sampling rate (SLAM-optimized)
   - 3-axis accelerometer + gyroscope + magnetometer
   - Hardware timestamp synchronization

2. **Data Serialization** (Pi)
   - JSON encoding with timestamps
   - UDP packet formation
   - Network byte ordering

3. **Network Transmission** (UDP)
   - Low-latency protocol
   - Fire-and-forget delivery
   - Port 5004

4. **Data Reception** (PC)
   - Non-blocking UDP socket
   - JSON parsing
   - Data validation

5. **Visualization** (PC)
   - Real-time graph rendering
   - ASCII bar charts
   - 50ms UI update interval

### FPS Monitoring Pipeline

1. **Connection** (PC → Pi)
   - TCP socket to video stream port
   - Single persistent connection per stream

2. **Data Consumption** (PC)
   - Aggressive 8KB reads
   - Continuous buffer draining
   - Side effect: reduces video latency

3. **Frame Detection** (PC)
   - H.264 NAL unit parsing (0x00000001)
   - JPEG SOI marker detection (0xFFD8)
   - Frame boundary identification

4. **FPS Calculation** (PC)
   - Per-second frame counting
   - Rolling average (10 samples)
   - Bandwidth tracking

5. **Display Updates** (PC)
   - Thread-safe data sharing
   - Real-time UI updates
   - Performance metrics

## Performance Characteristics

### Bandwidth Distribution
- **RGB Stream**: ~10 Mbps (1920x1080 @ 30fps, H.264 HIGH)
- **Left Camera**: ~4 Mbps (1280x720 @ 30fps, H.264 HIGH)
- **Right Camera**: ~4 Mbps (1280x720 @ 30fps, H.264 HIGH)
- **Depth Stream**: ~3-4 Mbps (Raw 16-bit uncompressed)
- **IMU Data**: <0.2 Mbps (JSON @ 200Hz)
- **Total**: ~21-22 Mbps (SLAM-optimized)

### Latency Profile
- **Camera → Pi**: <10ms (USB 3.0)
- **Pi Encoding**: ~25-35ms (H.264 HIGH profile)
- **Network**: <5ms (local ethernet)
- **PC Decode**: ~10-15ms (hardware accelerated)
- **Display**: ~16ms (60Hz refresh)
- **End-to-end**: <50ms with aggressive buffering

### Resource Usage
- **Pi CPU**: ~30-35% (quad-core ARM)
- **Pi Memory**: ~220MB
- **PC CPU**: ~10-15% (decoding + display)
- **PC Memory**: ~500MB (including buffers)
- **Network**: 14-15 Mbps sustained

## Key Optimizations

1. **Connection Pooling**: Single thread per stream prevents connection explosion
2. **Aggressive Buffering**: FPS monitor drains buffers, reducing latency
3. **Hardware Acceleration**: GStreamer uses GPU for H.264 decode
4. **Frame Rate Limiting**: 30 FPS cap prevents resource waste
5. **Non-blocking I/O**: Prevents stream stalls
6. **UDP for IMU**: Low-latency sensor data delivery
7. **Raw Depth Data**: 16-bit millimeter precision for SLAM

## Failure Modes & Recovery

1. **Camera Disconnect**: Automatic reconnection attempt
2. **Network Loss**: Client cleanup and re-registration
3. **Buffer Overflow**: Drop oldest frames (ring buffer)
4. **CPU Overload**: Frame dropping with telemetry
5. **Client Disconnect**: Automatic cleanup from client list

## SLAM Optimizations (v6.0)

### Raw Depth Streaming
- **Format**: 16-bit unsigned integers (uint16)
- **Units**: Millimeters from camera center
- **Header**: Width(4) + Height(4) + ItemSize(4) + Timestamp(8) bytes
- **Precision**: Metric depth values suitable for 3D reconstruction
- **Advantage**: No compression artifacts, full depth range preserved

### Video Quality Enhancement
- **Profile**: H.264 HIGH (upgraded from BASELINE)
- **Benefits**:
  - Better compression efficiency at same bitrate
  - Reduced visual artifacts for feature detection
  - Improved edge preservation for stereo matching
- **Bitrate**: Increased to maintain quality (10/4/4 Mbps)

### High-Frequency IMU
- **Frequency**: 200Hz (doubled from 100Hz)
- **Precision**: Better motion capture for dynamic scenarios
- **Latency**: <5ms UDP delivery
- **Format**: JSON with synchronized timestamps

### Temporal Synchronization
- **Method**: Host-based timestamps (time.time())
- **Precision**: Microsecond resolution
- **Coverage**: Depth and IMU streams share common time reference
- **Purpose**: Enables accurate sensor fusion for SLAM algorithms

### SLAM Applications
This architecture is optimized for:
- **Visual SLAM**: Stereo vision with high-quality feature extraction
- **Visual-Inertial Odometry**: 200Hz IMU with synchronized visual data
- **Dense Mapping**: Raw millimeter-precision depth reconstruction
- **Real-time Processing**: Low-latency synchronized sensor streams