#!/bin/bash
# Test triple streams with GStreamer - RGB + Left + Right

PI_IP="192.168.1.202"

echo "========================================="
echo "  Testing Triple Streams"
echo "========================================="
echo "Starting 3 video windows:"
echo "  RGB:   Port 5000 (Color)"
echo "  Left:  Port 5001 (Mono)"
echo "  Right: Port 5002 (Mono)"
echo ""

# Start RGB receiver
echo "Starting RGB receiver..."
gst-launch-1.0 tcpclientsrc host="$PI_IP" port=5000 ! h264parse ! avdec_h264 ! videoconvert ! autovideosink sync=false &
RGB_PID=$!

sleep 2

# Start Left receiver
echo "Starting Left camera receiver..."
gst-launch-1.0 tcpclientsrc host="$PI_IP" port=5001 ! h264parse ! avdec_h264 ! videoconvert ! autovideosink sync=false &
LEFT_PID=$!

sleep 2

# Start Right receiver
echo "Starting Right camera receiver..."
gst-launch-1.0 tcpclientsrc host="$PI_IP" port=5002 ! h264parse ! avdec_h264 ! videoconvert ! autovideosink sync=false &
RIGHT_PID=$!

echo ""
echo "All three receivers started!"
echo "RGB PID:   $RGB_PID"
echo "Left PID:  $LEFT_PID"
echo "Right PID: $RIGHT_PID"
echo ""
echo "You should see 3 windows:"
echo "  1. RGB Camera (color)"
echo "  2. Left Camera (mono)"
echo "  3. Right Camera (mono)"
echo ""
echo "Each window shows FPS in the title"
echo "Press Ctrl+C to stop all receivers"

# Wait and cleanup on interrupt
trap "kill $RGB_PID $LEFT_PID $RIGHT_PID 2>/dev/null; echo 'Stopped all receivers'" SIGINT SIGTERM

wait