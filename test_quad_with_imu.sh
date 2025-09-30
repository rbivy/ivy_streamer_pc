#!/bin/bash
# Clean quad stream test without video overlays + dedicated stats window
# Launches 6 windows: RGB, Left, Right, Depth (clean video), IMU data, and Stats monitor

PI_IP="192.168.1.201"  # Pi ethernet IP

echo "========================================="
echo "  Clean Quad Streams + Dual Interface Monitor"
echo "========================================="
echo "Starting 6 windows:"
echo "  RGB:   Port 5000 (1280x720 @ 30fps) - H.264 (clean)"
echo "  Left:  Port 5001 (1280x720 @ 30fps) - H.264 (clean)"
echo "  Right: Port 5002 (1280x720 @ 30fps) - H.264 (clean)"
echo "  Depth: Port 5003 (1280x720 @ 30fps) - Raw 16-bit (SLAM-ready)"
echo "  IMU:   Port 5004 (200Hz) - UDP JSON data (synchronized timestamps)"
echo "  Stats: Dual interface monitor (ethernet + WiFi)"
echo ""

# RGB Stream (H.264) - Clean, no overlays
echo "Starting RGB receiver..."
gst-launch-1.0 -v \
    tcpclientsrc host="$PI_IP" port=5000 ! \
    h264parse ! \
    avdec_h264 max-threads=1 ! \
    videoconvert ! \
    videoscale ! \
    "video/x-raw,width=1280,height=720,framerate=30/1" ! \
    autovideosink sync=false &
RGB_PID=$!

sleep 2

# Left Stream (H.264) - Clean, no overlays
echo "Starting Left camera receiver..."
gst-launch-1.0 -v \
    tcpclientsrc host="$PI_IP" port=5001 ! \
    h264parse ! \
    avdec_h264 max-threads=1 ! \
    videoconvert ! \
    "video/x-raw,framerate=30/1" ! \
    autovideosink sync=false &
LEFT_PID=$!

sleep 2

# Right Stream (H.264) - Clean, no overlays
echo "Starting Right camera receiver..."
gst-launch-1.0 -v \
    tcpclientsrc host="$PI_IP" port=5002 ! \
    h264parse ! \
    avdec_h264 max-threads=1 ! \
    videoconvert ! \
    "video/x-raw,framerate=30/1" ! \
    autovideosink sync=false &
RIGHT_PID=$!

sleep 2

# Raw 16-bit Depth Stream - SLAM-ready
echo "Starting Raw Depth receiver (SLAM-ready)..."
python3 -c "
import socket
import cv2
import numpy as np
import struct

def receive_raw_depth_stream():
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    try:
        sock.connect(('$PI_IP', 5003))
        print('Connected to raw 16-bit depth stream on port 5003')

        while True:
            # Receive frame size
            frame_size_data = sock.recv(4)
            if len(frame_size_data) != 4:
                break
            frame_size = struct.unpack('>I', frame_size_data)[0]

            # Receive frame data
            frame_data = b''
            while len(frame_data) < frame_size:
                chunk = sock.recv(min(65536, frame_size - len(frame_data)))
                if not chunk:
                    break
                frame_data += chunk

            if len(frame_data) == frame_size:
                # Parse header: width(4) + height(4) + itemsize(4) + timestamp(8)
                header = struct.unpack('>IIIQ', frame_data[:20])
                width, height, itemsize, timestamp_us = header

                # Extract raw 16-bit depth data
                depth_bytes = frame_data[20:]
                depth_raw = np.frombuffer(depth_bytes, dtype=np.uint16).reshape((height, width))

                # This is the raw depth in millimeters - perfect for SLAM!
                # For visualization, normalize to 0-255
                depth_normalized = cv2.normalize(depth_raw, None, 0, 255, cv2.NORM_MINMAX)
                depth_display = depth_normalized.astype(np.uint8)

                # Apply colormap for better visualization
                depth_colored = cv2.applyColorMap(depth_display, cv2.COLORMAP_JET)

                # Add overlay showing SLAM-ready status
                cv2.putText(depth_colored, 'Raw 16-bit Depth (SLAM-Ready)', (10, 30),
                           cv2.FONT_HERSHEY_SIMPLEX, 0.8, (255, 255, 255), 2)
                cv2.putText(depth_colored, f'Range: {depth_raw.min()}-{depth_raw.max()}mm', (10, 60),
                           cv2.FONT_HERSHEY_SIMPLEX, 0.7, (255, 255, 255), 2)
                cv2.putText(depth_colored, f'Timestamp: {timestamp_us/1000000:.3f}s', (10, 90),
                           cv2.FONT_HERSHEY_SIMPLEX, 0.7, (255, 255, 255), 2)

                cv2.imshow('SLAM-Ready Depth Stream', depth_colored)
                if cv2.waitKey(1) & 0xFF == ord('q'):
                    break

    except Exception as e:
        print(f'Raw depth stream error: {e}')
    finally:
        sock.close()
        cv2.destroyAllWindows()

receive_raw_depth_stream()
" &
DEPTH_PID=$!

sleep 2

# IMU Data Stream (UDP)
echo "Starting IMU data receiver window..."
python3 launch_imu_window.py &
IMU_PID=$!

sleep 2

# Stats Monitor - Dual interface monitoring (ethernet + WiFi)
echo "Starting dual interface bandwidth monitor GUI..."
python3 dual_interface_monitor.py &
STATS_PID=$!

echo ""
echo "All six receivers started!"
echo "RGB PID:   $RGB_PID"
echo "Left PID:  $LEFT_PID"
echo "Right PID: $RIGHT_PID"
echo "Depth PID: $DEPTH_PID"
echo "IMU PID: $IMU_PID"
echo "Stats PID: $STATS_PID"
echo ""
echo "Video streams: Clean video without overlays for SLAM processing"
echo "Stats window: Comprehensive bandwidth and performance monitoring"
echo ""
echo "Press Ctrl+C to stop all receivers and Pi processes"

# Enhanced cleanup function - stops both PC receivers and Pi processes
cleanup() {
    echo ""
    echo "Stopping all streams..."

    # Stop PC receivers
    echo "Stopping PC receivers..."
    kill $RGB_PID $LEFT_PID $RIGHT_PID $DEPTH_PID $STATS_PID 2>/dev/null || true

    # Kill IMU and stats processes
    pkill -f "launch_imu_window.py" 2>/dev/null || true
    pkill -f "dual_interface_monitor.py" 2>/dev/null || true

    # Stop Pi quad streamer processes
    echo "Stopping Pi quad streamer with IMU..."
    ./ssh_pi_optimized.sh "pkill -f quad_streamer.py" 2>/dev/null || true
    ./ssh_pi_optimized.sh "pkill -f quad_streamer_with_imu.py" 2>/dev/null || true

    echo "All receivers and Pi processes stopped"
}

trap cleanup SIGINT SIGTERM

# Wait for user to terminate with Ctrl+C (no auto-monitoring)
echo "All processes running. Press Ctrl+C to stop all streams when ready."
echo ""

# Wait indefinitely - user controls when to stop
# Also add EXIT trap to ensure cleanup on script termination
trap 'cleanup; exit 0' EXIT
wait