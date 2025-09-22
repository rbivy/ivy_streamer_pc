#!/bin/bash
# Comprehensive startup script: Pi quad streamer with IMU + PC receivers with IMU display
# Handles cleanup, startup, and verification automatically

echo "========================================="
echo "  Complete Quad Stream + IMU Data Setup"
echo "========================================="
echo "This script will:"
echo "  1. Start Pi quad streamer with IMU (RGB + Left + Right + Depth + IMU)"
echo "  2. Start PC receivers with advanced overlays + IMU terminal"
echo ""

# Start Pi streamer with automatic cleanup
echo "Step 1: Stopping any existing streamers on Pi..."
./ssh_pi_robust.sh "pkill -f triple_streamer.py || true; pkill -f quad_streamer.py || true; pkill -f quad_streamer_with_imu.py || true"
sleep 2

echo "Starting quad streamer with IMU on Pi..."
./ssh_pi_robust.sh "cd /home/ivyspec/ivy_streamer && source venv/bin/activate && python quad_streamer_with_imu.py" &
PI_STREAMER_PID=$!

# Wait for streamer initialization
echo "Waiting 15 seconds for Pi quad+IMU streamer initialization..."
sleep 15

# Check if ports are accessible
echo "Verifying quad stream ports..."
all_ports_ok=true
for port in 5000 5001 5002 5003; do
    if nc -zv 192.168.1.202 $port 2>/dev/null; then
        echo "✓ Port $port: OK (video stream)"
    else
        echo "✗ Port $port: NOT ACCESSIBLE"
        all_ports_ok=false
    fi
done

# Check UDP port for IMU (this will likely fail with nc but that's okay)
echo "✓ Port 5004: UDP (IMU data) - will connect when receiver starts"

if [ "$all_ports_ok" = false ]; then
    echo ""
    echo "❌ Some video ports not accessible. Check the Pi output."
    echo "Stopping Pi streamer..."
    ./ssh_pi_robust.sh "pkill -f quad_streamer_with_imu.py" 2>/dev/null || true
    exit 1
fi

echo ""
echo "✓ All video stream ports accessible"
echo ""
echo "Step 2: Starting PC receivers with advanced overlays and IMU display..."
echo "This will open:"
echo "  - 4 video windows (RGB, Left, Right, Depth)"
echo "  - 1 GUI window for IMU data"
echo ""
echo "Press Ctrl+C to stop all streams when done"
echo ""

# Cleanup function for both Pi and PC processes
cleanup() {
    echo ""
    echo "Stopping all streams..."
    echo "Stopping PC receivers..."
    pkill -f "gst-launch-1.0.*tcpclientsrc" 2>/dev/null || true
    pkill -f "imu_receiver.py" 2>/dev/null || true

    echo "Stopping Pi quad streamer with IMU..."
    ./ssh_pi_robust.sh "pkill -f quad_streamer_with_imu.py" 2>/dev/null || true

    echo "All streams stopped"
}

trap cleanup SIGINT SIGTERM

# Start the PC receivers with IMU
./test_quad_advanced_overlay_with_imu.sh