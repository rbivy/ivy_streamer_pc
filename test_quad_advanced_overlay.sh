#!/bin/bash
# Advanced quad stream test with detailed telemetry overlays including depth

PI_IP="192.168.1.202"

echo "========================================="
echo "  Advanced Quad Streams with Depth"
echo "========================================="
echo "Starting 4 video windows with detailed stats:"
echo "  RGB:   Port 5000 (1920x1080 @ 30fps)"
echo "  Left:  Port 5001 (1280x720 @ 30fps)"
echo "  Right: Port 5002 (1280x720 @ 30fps)"
echo "  Depth: Port 5003 (1280x720 @ 30fps)"
echo ""

# Function to create timestamp
get_timestamp() {
    date +"%H:%M:%S"
}

# RGB Stream with detailed overlay
echo "Starting RGB receiver with detailed overlay..."
gst-launch-1.0 -v \
    tcpclientsrc host="$PI_IP" port=5000 ! \
    h264parse ! \
    avdec_h264 ! \
    videoconvert ! \
    clockoverlay halignment=right valignment=top font-desc="Sans, 10" \
        time-format="%D %H:%M:%S" ! \
    textoverlay text="RGB Stream | 1920x1080 @ 30fps | Port 5000" \
        valignment=top halignment=left font-desc="Sans Bold, 12" \
        shaded-background=true ! \
    fpsdisplaysink text-overlay=true video-sink=autovideosink sync=false \
        signal-fps-measurements=true &
RGB_PID=$!

sleep 2

# Left Stream with detailed overlay
echo "Starting Left camera receiver with detailed overlay..."
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
    fpsdisplaysink text-overlay=true video-sink=autovideosink sync=false \
        signal-fps-measurements=true &
LEFT_PID=$!

sleep 2

# Right Stream with detailed overlay
echo "Starting Right camera receiver with detailed overlay..."
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
    fpsdisplaysink text-overlay=true video-sink=autovideosink sync=false \
        signal-fps-measurements=true &
RIGHT_PID=$!

sleep 2

# Depth Stream with detailed overlay
echo "Starting Depth receiver with detailed overlay..."
gst-launch-1.0 -v \
    tcpclientsrc host="$PI_IP" port=5003 ! \
    h264parse ! \
    avdec_h264 ! \
    videoconvert ! \
    clockoverlay halignment=right valignment=top font-desc="Sans, 10" \
        time-format="%D %H:%M:%S" ! \
    textoverlay text="Depth Stream | 1280x720 @ 30fps | Port 5003" \
        valignment=top halignment=left font-desc="Sans Bold, 12" \
        shaded-background=true ! \
    fpsdisplaysink text-overlay=true video-sink=autovideosink sync=false \
        signal-fps-measurements=true &
DEPTH_PID=$!

echo ""
echo "All four receivers started with advanced overlays!"
echo "RGB PID:   $RGB_PID"
echo "Left PID:  $LEFT_PID"
echo "Right PID: $RIGHT_PID"
echo "Depth PID: $DEPTH_PID"
echo ""
echo "Each window displays:"
echo "  - Stream identifier and specs (top left)"
echo "  - Current date/time (top right)"
echo "  - Real-time FPS counter (bottom)"
echo ""
echo "Depth stream shows stereo-computed depth map in grayscale"
echo "Press Ctrl+C to stop all receivers"

# Monitor and display stats
display_stats() {
    while true; do
        sleep 5
        echo ""
        echo "========================================="
        echo "Stream Status at $(get_timestamp)"
        echo "========================================="

        # Check if processes are still running
        if ps -p $RGB_PID > /dev/null 2>&1; then
            echo "✓ RGB Stream:   ACTIVE (PID $RGB_PID)"
        else
            echo "✗ RGB Stream:   STOPPED"
        fi

        if ps -p $LEFT_PID > /dev/null 2>&1; then
            echo "✓ Left Stream:  ACTIVE (PID $LEFT_PID)"
        else
            echo "✗ Left Stream:  STOPPED"
        fi

        if ps -p $RIGHT_PID > /dev/null 2>&1; then
            echo "✓ Right Stream: ACTIVE (PID $RIGHT_PID)"
        else
            echo "✗ Right Stream: STOPPED"
        fi

        if ps -p $DEPTH_PID > /dev/null 2>&1; then
            echo "✓ Depth Stream: ACTIVE (PID $DEPTH_PID)"
        else
            echo "✗ Depth Stream: STOPPED"
        fi
    done
}

# Start monitoring in background
display_stats &
MONITOR_PID=$!

# Cleanup on interrupt
cleanup() {
    echo ""
    echo "Stopping all streams..."
    kill $RGB_PID $LEFT_PID $RIGHT_PID $DEPTH_PID $MONITOR_PID 2>/dev/null
    echo "All receivers stopped"
}

trap cleanup SIGINT SIGTERM

wait