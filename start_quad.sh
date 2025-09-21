#!/bin/bash
# Start quad streamer with depth support and proper cleanup
# Automatically kills existing streamers before starting new ones

PI_IP="192.168.1.202"
PI_USER="ivyspec"
PI_PASSWORD="ivyspec"
PROJECT_DIR="/home/ivyspec/ivy_streamer"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

echo "========================================="
echo "  Quad Streamer Startup with Depth"
echo "========================================="
echo "Target: $PI_USER@$PI_IP"
echo "Project: $PROJECT_DIR"
echo ""

# Check dependencies
if ! command -v sshpass &> /dev/null; then
    print_error "sshpass not found. Install it with:"
    print_info "sudo apt update && sudo apt install sshpass"
    exit 1
fi

# Check Pi connectivity
print_info "Checking Pi connectivity..."
if ! ping -c 1 -W 3 "$PI_IP" &> /dev/null; then
    print_error "Cannot reach Pi at $PI_IP"
    print_info "Check Pi is powered on and connected to network"
    exit 1
fi
print_status "Pi is reachable"

# Test SSH connectivity
print_info "Testing SSH connection..."
if ! sshpass -p "$PI_PASSWORD" ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no \
    "$PI_USER@$PI_IP" "echo 'SSH test successful'" &> /dev/null; then
    print_error "SSH connection failed"
    print_info "Check Pi SSH is enabled and credentials are correct"
    exit 1
fi
print_status "SSH connection verified"

# Kill any existing streamers
print_info "Stopping any existing streamers..."
sshpass -p "$PI_PASSWORD" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_IP" \
    "pkill -f triple_streamer.py; pkill -f quad_streamer.py" 2>/dev/null || true

# Wait for cleanup
sleep 2

# Verify ports are free
print_info "Checking if streaming ports are available..."
port_check() {
    local port=$1
    if sshpass -p "$PI_PASSWORD" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_IP" \
        "ss -tuln | grep :$port" &> /dev/null; then
        return 1  # Port is in use
    else
        return 0  # Port is free
    fi
}

# Check all four ports (including depth port 5003)
ports_ready=true
for port in 5000 5001 5002 5003; do
    if port_check $port; then
        print_status "Port $port is available"
    else
        print_warning "Port $port is still in use, waiting..."
        sleep 3
        if port_check $port; then
            print_status "Port $port is now available"
        else
            print_error "Port $port remains in use after cleanup"
            ports_ready=false
        fi
    fi
done

if [ "$ports_ready" = false ]; then
    print_error "Some ports are still in use. Manual cleanup may be required."
    print_info "Try: ./ssh_pi_robust.sh \"sudo fuser -k 5000/tcp 5001/tcp 5002/tcp 5003/tcp\""
    exit 1
fi

# Start new quad streamer
print_info "Starting quad streamer with depth..."
echo ""

if sshpass -p "$PI_PASSWORD" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_IP" \
    "cd $PROJECT_DIR && source venv/bin/activate && python quad_streamer.py" &
then
    STREAMER_PID=$!
    print_status "Quad streamer started successfully (background PID: $STREAMER_PID)"

    # Wait for initialization
    print_info "Waiting for streamer initialization..."
    sleep 10

    # Verify ports are now listening
    print_info "Verifying streaming ports..."
    all_ports_ready=true
    port_names=("5000: RGB" "5001: Left" "5002: Right" "5003: Depth")
    for i in {0..3}; do
        port=$((5000 + i))
        if nc -z -w5 "$PI_IP" $port 2>/dev/null; then
            print_status "Port ${port_names[$i]} stream ready"
        else
            print_error "Port ${port_names[$i]} stream not ready"
            all_ports_ready=false
        fi
    done

    echo ""
    if [ "$all_ports_ready" = true ]; then
        print_status "All quad streams are ready!"
        echo ""
        print_info "Stream details:"
        echo "  RGB Camera:   $PI_IP:5000 (1920x1080 @ 30fps)"
        echo "  Left Camera:  $PI_IP:5001 (1280x720 @ 30fps)"
        echo "  Right Camera: $PI_IP:5002 (1280x720 @ 30fps)"
        echo "  Depth Stream: $PI_IP:5003 (1280x720 @ 30fps)"
        echo ""
        print_info "You can now start the PC receivers:"
        echo "  ./test_quad_advanced_overlay.sh     # Quad streams with depth (recommended)"
        echo "  ./test_triple_advanced_overlay.sh   # Triple streams only"
        echo "  ./test_triple.sh                    # Simple receivers"
        echo ""
        print_info "To stop the streamer: ./ssh_pi_robust.sh \"pkill -f quad_streamer.py\""
    else
        print_error "Some streams failed to start properly"
        print_info "Check Pi logs: ./ssh_pi_robust.sh \"tail -f ivy_streamer.log\""
        exit 1
    fi
else
    print_error "Failed to start quad streamer"
    exit 1
fi