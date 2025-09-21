#!/bin/bash
# Advanced quad stream test with JPEG depth stream

PI_IP="192.168.1.202"

echo "========================================="
echo "  Advanced Quad Streams with Depth"
echo "========================================="
echo "Starting 4 video windows:"
echo "  RGB:   Port 5000 (1280x720 @ 30fps) - H.264"
echo "  Left:  Port 5001 (1280x720 @ 30fps) - H.264"
echo "  Right: Port 5002 (1280x720 @ 30fps) - H.264"
echo "  Depth: Port 5003 (1280x720 @ 30fps) - JPEG"
echo ""

# RGB Stream (H.264)
echo "Starting RGB receiver..."
gst-launch-1.0 -v \
    tcpclientsrc host="$PI_IP" port=5000 ! \
    h264parse ! \
    avdec_h264 ! \
    videoconvert ! \
    clockoverlay halignment=right valignment=top font-desc="Sans, 10" \
        time-format="%D %H:%M:%S" ! \
    textoverlay text="RGB Stream | 1280x720 @ 30fps | Port 5000" \
        valignment=top halignment=left font-desc="Sans Bold, 12" \
        shaded-background=true ! \
    fpsdisplaysink text-overlay=true video-sink=autovideosink sync=false &
RGB_PID=$!

sleep 2

# Left Stream (H.264)
echo "Starting Left camera receiver..."
gst-launch-1.0 -v \
    tcpclientsrc host="$PI_IP" port=5001 ! \
    h264parse ! \
    avdec_h264 ! \
    videoconvert ! \
    clockoverlay halignment=right valignment=top font-desc="Sans, 10" \
        time-format="%D %H:%M:%S" ! \
    textoverlay text="Left Camera | 1280x720 @ 30fps | Port 5001" \
        valignment=top halignment=left font-desc="Sans Bold, 12" \
        shaded-background=true ! \
    fpsdisplaysink text-overlay=true video-sink=autovideosink sync=false &
LEFT_PID=$!

sleep 2

# Right Stream (H.264)
echo "Starting Right camera receiver..."
gst-launch-1.0 -v \
    tcpclientsrc host="$PI_IP" port=5002 ! \
    h264parse ! \
    avdec_h264 ! \
    videoconvert ! \
    clockoverlay halignment=right valignment=top font-desc="Sans, 10" \
        time-format="%D %H:%M:%S" ! \
    textoverlay text="Right Camera | 1280x720 @ 30fps | Port 5002" \
        valignment=top halignment=left font-desc="Sans Bold, 12" \
        shaded-background=true ! \
    fpsdisplaysink text-overlay=true video-sink=autovideosink sync=false &
RIGHT_PID=$!

sleep 2

# Depth Stream (JPEG)
echo "Starting Depth receiver..."
python3 -c "
import socket
import cv2
import numpy as np
import struct
import time

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
                # Decode JPEG
                img_array = np.frombuffer(frame_data, np.uint8)
                depth_img = cv2.imdecode(img_array, cv2.IMREAD_GRAYSCALE)

                if depth_img is not None:
                    # Add text overlay
                    cv2.putText(depth_img, 'Depth Stream | 1280x720 @ 30fps | Port 5003',
                               (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.7, 255, 2)
                    cv2.putText(depth_img, time.strftime('%m/%d/%Y %H:%M:%S'),
                               (depth_img.shape[1]-200, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.5, 255, 1)

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

echo ""
echo "All four receivers started!"
echo "RGB PID:   $RGB_PID"
echo "Left PID:  $LEFT_PID"
echo "Right PID: $RIGHT_PID"
echo "Depth PID: $DEPTH_PID"
echo ""
echo "RGB, Left, Right: H.264 streams with GStreamer overlays"
echo "Depth: JPEG stream with OpenCV display"
echo ""
echo "Press Ctrl+C or close any video window to stop all receivers and Pi processes"

# Enhanced cleanup function - stops both PC receivers and Pi processes
cleanup() {
    echo ""
    echo "Stopping all streams..."

    # Stop monitor process if running
    if [ ! -z "$MONITOR_PID" ]; then
        kill $MONITOR_PID 2>/dev/null || true
    fi

    # Stop PC receivers
    echo "Stopping PC receivers..."
    kill $RGB_PID $LEFT_PID $RIGHT_PID $DEPTH_PID 2>/dev/null || true

    # Stop Pi quad streamer processes
    echo "Stopping Pi quad streamer..."
    ./ssh_pi_robust.sh "pkill -f quad_streamer.py" 2>/dev/null || true

    echo "All receivers and Pi processes stopped"
}

trap cleanup SIGINT SIGTERM

# Monitor processes and cleanup when any exit
monitor_processes() {
    while true; do
        # Check if any of the main processes have exited
        if ! kill -0 $RGB_PID 2>/dev/null || ! kill -0 $LEFT_PID 2>/dev/null || ! kill -0 $RIGHT_PID 2>/dev/null || ! kill -0 $DEPTH_PID 2>/dev/null; then
            echo ""
            echo "Video window closed or process exited. Cleaning up..."
            cleanup
            exit 0
        fi
        sleep 1
    done
}

# Start monitoring in background and wait for processes
monitor_processes &
MONITOR_PID=$!

wait