#!/bin/bash
# Optimized startup script: Pi quad streamer with IMU + PC receivers
# Uses fast SSH key authentication

echo "========================================="
echo "  Optimized Quad Stream + IMU Data Setup"
echo "========================================="
echo "Using fast SSH key authentication..."
echo ""

# Stop any existing streamers quickly
echo "Step 1: Stopping any existing streamers on Pi..."
time ./ssh_pi_optimized.sh "pkill -f quad_streamer || true"
sleep 2

# Start Pi streamer
echo "Starting quad streamer with IMU on Pi..."
time ./ssh_pi_optimized.sh "cd /home/ivyspec/ivy_streamer && source venv/bin/activate && nohup python quad_streamer_with_imu.py > /dev/null 2>&1 & echo 'Streamer started'"

# Wait for initialization
echo "Waiting 15 seconds for Pi quad+IMU streamer initialization..."
sleep 15

# Quick verification
echo "Verifying Pi streamer status..."
./ssh_pi_optimized.sh "ps aux | grep quad_streamer | grep -v grep | wc -l" | grep -q "1" && echo "✓ Pi streamer running" || echo "✗ Pi streamer not found"

# Check ports
echo "Verifying quad stream ports..."
all_ports_ok=true
for port in 5000 5001 5002 5003; do
    if nc -zv 192.168.1.201 $port 2>/dev/null; then
        echo "✓ Port $port: OK (video stream)"
    else
        echo "✗ Port $port: NOT ACCESSIBLE"
        all_ports_ok=false
    fi
done

echo "✓ Port 5004: UDP (IMU data) - will connect when receiver starts"

if [ "$all_ports_ok" = false ]; then
    echo ""
    echo "❌ Some video ports not accessible. Check the Pi output."
    echo "Stopping Pi streamer..."
    ./ssh_pi_optimized.sh "pkill -f quad_streamer"
    exit 1
fi

echo ""
echo "✓ All video stream ports accessible"
echo ""
echo "Step 2: Starting PC receivers with advanced overlays and IMU display..."
echo "This will open:"
echo "  - 4 video windows (RGB, Left, Right, Depth)"
echo "  - 1 GUI window for IMU data"
echo "  - 1 network monitoring window"
echo ""

# Cleanup function
cleanup() {
    echo ""
    echo "Stopping all streams..."
    echo "Stopping PC receivers..."
    pkill -f "gst-launch-1.0.*tcpclientsrc" 2>/dev/null || true
    pkill -f "launch_imu_window.py" 2>/dev/null || true
    pkill -f "dual_interface_monitor.py" 2>/dev/null || true

    echo "Stopping Pi quad streamer with optimized SSH..."
    ./ssh_pi_optimized.sh "pkill -f quad_streamer" 2>/dev/null || true

    echo "All streams stopped"
}

trap cleanup SIGINT SIGTERM

# Start PC receivers
./test_quad_with_imu.sh