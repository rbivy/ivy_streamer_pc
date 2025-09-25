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
echo "  Depth: Port 5003 (1280x720 @ 30fps) - JPEG (clean)"
echo "  IMU:   Port 5004 (100Hz) - UDP JSON data"
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
    "video/x-raw,width=1280,height=720" ! \
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
    autovideosink sync=false &
RIGHT_PID=$!

sleep 2

# Depth Stream (JPEG) - Clean, no overlays
echo "Starting Depth receiver..."
python3 -c "
import socket
import cv2
import numpy as np
import struct

def receive_depth_stream():
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    try:
        sock.connect(('$PI_IP', 5003))
        print('Connected to depth stream on port 5003')

        while True:
            # Receive frame size
            frame_size_data = sock.recv(4)
            if len(frame_size_data) != 4:
                break
            frame_size = struct.unpack('>I', frame_size_data)[0]

            # Receive frame data
            frame_data = b''
            while len(frame_data) < frame_size:
                chunk = sock.recv(frame_size - len(frame_data))
                if not chunk:
                    break
                frame_data += chunk

            if len(frame_data) == frame_size:
                # Decode JPEG - clean display
                img_array = np.frombuffer(frame_data, np.uint8)
                depth_img = cv2.imdecode(img_array, cv2.IMREAD_GRAYSCALE)

                if depth_img is not None:
                    cv2.imshow('Depth Stream', depth_img)
                    if cv2.waitKey(1) & 0xFF == ord('q'):
                        break

    except Exception as e:
        print(f'Depth stream error: {e}')
    finally:
        sock.close()
        cv2.destroyAllWindows()

receive_depth_stream()
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