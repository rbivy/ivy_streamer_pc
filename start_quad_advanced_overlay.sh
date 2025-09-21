#!/bin/bash
# Comprehensive startup script: Pi quad streamer + PC receivers with depth stream
# Handles cleanup, startup, and verification automatically

echo "========================================="
echo "  Complete Quad Stream Setup with Depth"
echo "========================================="
echo "This script will:"
echo "  1. Start Pi quad streamer (RGB + Left + Right + Depth)"
echo "  2. Start PC receivers with advanced overlays"
echo ""

# Start Pi streamer with automatic cleanup
echo "Step 1: Starting Pi quad streamer with depth..."
./ssh_pi_robust.sh "pkill -f triple_streamer.py || true; pkill -f quad_streamer.py || true"
sleep 2

echo "Starting quad streamer on Pi..."
./ssh_pi_robust.sh "cd /home/ivyspec/ivy_streamer && source venv/bin/activate && python quad_streamer.py" &
PI_STREAMER_PID=$!

# Wait for streamer initialization
echo "Waiting 15 seconds for Pi quad streamer initialization..."
sleep 15

# Check if ports are accessible
echo "Verifying quad stream ports..."
if nc -zv 192.168.1.202 5000 5001 5002 5003 2>/dev/null; then
    echo "✓ All quad stream ports accessible"
else
    echo "❌ Some ports not accessible. Checking individual ports..."
    for port in 5000 5001 5002 5003; do
        if nc -zv 192.168.1.202 $port 2>/dev/null; then
            echo "✓ Port $port: OK"
        else
            echo "✗ Port $port: NOT ACCESSIBLE"
        fi
    done
    echo ""
    echo "❌ Failed to start Pi quad streamer. Check the Pi output."
    exit 1
fi

echo ""
echo "Step 2: Starting PC receivers with advanced overlays..."
echo "Press Ctrl+C to stop all streams when done"
echo ""

# Cleanup function for both Pi and PC processes
cleanup() {
    echo ""
    echo "Stopping all streams..."
    echo "Stopping PC receivers..."
    pkill -f "gst-launch-1.0.*tcpclientsrc" 2>/dev/null || true

    echo "Stopping Pi quad streamer..."
    ./ssh_pi_robust.sh "pkill -f quad_streamer.py" 2>/dev/null || true

    echo "All quad streams stopped"
}

trap cleanup SIGINT SIGTERM

# Start the PC receivers
./test_quad_advanced_overlay.sh