#!/bin/bash
# Comprehensive startup script: Pi streamer + PC receivers with advanced overlays
# Handles cleanup, startup, and verification automatically

echo "========================================="
echo "  Complete Triple Stream Setup"
echo "========================================="
echo "This script will:"
echo "  1. Start Pi streamer with cleanup"
echo "  2. Start PC receivers with advanced overlays"
echo ""

# Start Pi streamer with automatic cleanup
echo "Step 1: Starting Pi streamer..."
./start_triple.sh

if [ $? -ne 0 ]; then
    echo "❌ Failed to start Pi streamer. Check the output above."
    exit 1
fi

echo ""
echo "Step 2: Starting PC receivers with advanced overlays..."
echo "Press Ctrl+C to stop all streams when done"
echo ""

# Start the PC receivers
./test_triple_advanced_overlay.sh