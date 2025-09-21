#!/bin/bash
# Enhanced triple stream test with on-screen telemetry overlays

PI_IP="192.168.1.202"

echo "========================================="
echo "  Triple Streams with Telemetry Overlays"
echo "========================================="
echo "Starting 3 video windows with real-time stats:"
echo "  RGB:   Port 5000 (1920x1080 @ 30fps)"
echo "  Left:  Port 5001 (1280x720 @ 30fps)"
echo "  Right: Port 5002 (1280x720 @ 30fps)"
echo ""
echo "Each window will display:"
echo "  - Stream name and resolution"
echo "  - Real-time FPS counter"
echo "  - Frame statistics"
echo "  - Bitrate information"
echo ""

# RGB Stream with overlay
echo "Starting RGB receiver with overlay..."
gst-launch-1.0 -v \
    tcpclientsrc host="$PI_IP" port=5000 ! \
    h264parse ! \
    avdec_h264 ! \
    videoconvert ! \
    fpsdisplaysink text-overlay=true video-sink=autovideosink sync=false \
    signal-fps-measurements=true \
    name="RGB Stream - 1920x1080" &
RGB_PID=$!

sleep 2

# Left Stream with overlay
echo "Starting Left camera receiver with overlay..."
gst-launch-1.0 -v \
    tcpclientsrc host="$PI_IP" port=5001 ! \
    h264parse ! \
    avdec_h264 ! \
    videoconvert ! \
    fpsdisplaysink text-overlay=true video-sink=autovideosink sync=false \
    signal-fps-measurements=true \
    name="Left Camera - 1280x720" &
LEFT_PID=$!

sleep 2

# Right Stream with overlay
echo "Starting Right camera receiver with overlay..."
gst-launch-1.0 -v \
    tcpclientsrc host="$PI_IP" port=5002 ! \
    h264parse ! \
    avdec_h264 ! \
    videoconvert ! \
    fpsdisplaysink text-overlay=true video-sink=autovideosink sync=false \
    signal-fps-measurements=true \
    name="Right Camera - 1280x720" &
RIGHT_PID=$!

echo ""
echo "All three receivers started with overlays!"
echo "RGB PID:   $RGB_PID"
echo "Left PID:  $LEFT_PID"
echo "Right PID: $RIGHT_PID"
echo ""
echo "You should see 3 windows with FPS overlays"
echo "Press Ctrl+C to stop all receivers"

# Cleanup on interrupt
trap "kill $RGB_PID $LEFT_PID $RIGHT_PID 2>/dev/null; echo 'Stopped all receivers'" SIGINT SIGTERM

wait