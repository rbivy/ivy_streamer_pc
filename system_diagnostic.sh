#!/bin/bash

# System Diagnostic Script for OAK-D Pro Streaming
# Comprehensive system check and troubleshooting

PI_IP="192.168.1.202"
PI_USER="ivyspec"
PI_PASSWORD="ivyspec"
PORT="5000"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${CYAN}================================${NC}"
    echo -e "${CYAN} $1${NC}"
    echo -e "${CYAN}================================${NC}"
}

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

# System information
check_system_info() {
    print_header "SYSTEM INFORMATION"

    echo "Date: $(date)"
    echo "User: $(whoami)"
    echo "Working Directory: $(pwd)"
    echo "OS: $(lsb_release -d 2>/dev/null | cut -f2 || echo "Unknown")"
    echo "Kernel: $(uname -r)"
    echo "Architecture: $(uname -m)"
    echo ""
}

# Network connectivity
check_network() {
    print_header "NETWORK CONNECTIVITY"

    # Check local network
    print_info "Checking local network interface..."
    ip route show | head -5
    echo ""

    # Check Pi connectivity
    print_info "Testing Pi connectivity..."
    if ping -c 3 -W 2 "$PI_IP" &> /dev/null; then
        print_status "Pi reachable at $PI_IP"

        # Get ping statistics
        ping_stats=$(ping -c 5 -W 2 "$PI_IP" 2>/dev/null | tail -1)
        echo "  Ping stats: $ping_stats"
    else
        print_error "Pi unreachable at $PI_IP"
    fi

    # Check SSH port
    print_info "Testing SSH port..."
    if nc -z -w5 "$PI_IP" 22 2>/dev/null; then
        print_status "SSH port (22) accessible"
    else
        print_error "SSH port (22) not accessible"
    fi

    # Check streaming port
    print_info "Testing streaming port..."
    if nc -z -w5 "$PI_IP" "$PORT" 2>/dev/null; then
        print_status "Streaming port ($PORT) accessible"
    else
        print_warning "Streaming port ($PORT) not accessible (streamer may not be running)"
    fi
    echo ""
}

# Dependencies check
check_dependencies() {
    print_header "DEPENDENCY CHECK"

    local deps=("ssh" "sshpass" "nc" "ping" "gst-launch-1.0" "gst-inspect-1.0")
    local missing=()

    for dep in "${deps[@]}"; do
        if command -v "$dep" &> /dev/null; then
            print_status "$dep: $(which "$dep")"
        else
            print_error "$dep: NOT FOUND"
            missing+=("$dep")
        fi
    done

    if [ ${#missing[@]} -ne 0 ]; then
        echo ""
        print_warning "Missing dependencies: ${missing[*]}"
        print_info "Install with: sudo apt update && sudo apt install openssh-client sshpass netcat-openbsd iputils-ping gstreamer1.0-tools"
    fi
    echo ""
}

# GStreamer plugins check
check_gstreamer() {
    print_header "GSTREAMER PLUGINS"

    local plugins=("tcpclientsrc" "h264parse" "avdec_h264" "videoconvert" "fpsdisplaysink" "autovideosink")

    for plugin in "${plugins[@]}"; do
        if gst-inspect-1.0 "$plugin" &> /dev/null; then
            print_status "$plugin: Available"
        else
            print_error "$plugin: NOT AVAILABLE"
        fi
    done

    echo ""
    print_info "GStreamer version: $(gst-launch-1.0 --version 2>&1 | head -1)"
    echo ""
}

# SSH connectivity test
check_ssh() {
    print_header "SSH CONNECTIVITY"

    if ! command -v sshpass &> /dev/null; then
        print_error "sshpass not available - cannot test SSH"
        return
    fi

    print_info "Testing SSH authentication..."
    if sshpass -p "$PI_PASSWORD" ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no \
        "$PI_USER@$PI_IP" "echo 'SSH test successful'" 2>/dev/null; then
        print_status "SSH authentication successful"

        # Get Pi system info
        print_info "Pi system information:"
        sshpass -p "$PI_PASSWORD" ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no \
            "$PI_USER@$PI_IP" "uname -a; uptime" 2>/dev/null | sed 's/^/  /'
    else
        print_error "SSH authentication failed"
        print_info "Check credentials: $PI_USER@$PI_IP"
    fi
    echo ""
}

# Pi streaming status
check_pi_status() {
    print_header "PI STREAMING STATUS"

    if ! command -v sshpass &> /dev/null; then
        print_error "sshpass not available - cannot check Pi status"
        return
    fi

    print_info "Checking Pi streaming processes..."

    # Check for streaming processes
    local processes
    processes=$(sshpass -p "$PI_PASSWORD" ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no \
        "$PI_USER@$PI_IP" "ps aux | grep -E '(streamer|gst-launch)' | grep -v grep" 2>/dev/null || echo "")

    if [ -n "$processes" ]; then
        print_status "Streaming processes found:"
        echo "$processes" | sed 's/^/  /'
    else
        print_warning "No streaming processes found"
        print_info "Start with: ./start_streamer.sh"
    fi

    # Check camera connection
    print_info "Checking OAK-D Pro camera connection..."
    local camera_check
    camera_check=$(sshpass -p "$PI_PASSWORD" ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no \
        "$PI_USER@$PI_IP" "lsusb | grep -i movidius" 2>/dev/null || echo "")

    if [ -n "$camera_check" ]; then
        print_status "OAK-D Pro camera detected:"
        echo "$camera_check" | sed 's/^/  /'
    else
        print_warning "OAK-D Pro camera not detected"
        print_info "Check USB connection and camera power"
    fi

    # Check project directory
    print_info "Checking project directory..."
    if sshpass -p "$PI_PASSWORD" ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no \
        "$PI_USER@$PI_IP" "[ -d /home/ivyspec/ivy_streamer ]" 2>/dev/null; then
        print_status "Project directory exists"

        # Check key files
        local files=("streamer_v3.py" "venv/bin/activate")
        for file in "${files[@]}"; do
            if sshpass -p "$PI_PASSWORD" ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no \
                "$PI_USER@$PI_IP" "[ -f /home/ivyspec/ivy_streamer/$file ]" 2>/dev/null; then
                print_status "$file: Present"
            else
                print_error "$file: Missing"
            fi
        done
    else
        print_error "Project directory not found"
    fi
    echo ""
}

# Performance test
performance_test() {
    print_header "PERFORMANCE TEST"

    if ! nc -z -w5 "$PI_IP" "$PORT" 2>/dev/null; then
        print_warning "Streaming port not accessible - skipping performance test"
        print_info "Start the streamer first: ./start_streamer.sh"
        return
    fi

    print_info "Running 10-second GStreamer performance test..."

    local temp_log="/tmp/gst_perf_test.log"
    timeout 10 gst-launch-1.0 \
        tcpclientsrc host="$PI_IP" port="$PORT" ! \
        h264parse ! \
        avdec_h264 ! \
        videoconvert ! \
        fpsdisplaysink sync=false text-overlay=true video-sink=fakesink \
        -v &> "$temp_log" 2>&1

    # Extract performance data
    local avg_fps
    avg_fps=$(grep "average:" "$temp_log" | tail -1 | grep -o 'average: [0-9.]*' | cut -d' ' -f2 2>/dev/null || echo "Unknown")

    print_status "Average FPS: $avg_fps"

    # Check for errors
    local error_count
    error_count=$(grep -c "ERROR\|error" "$temp_log" 2>/dev/null || echo "0")

    if [ "$error_count" -eq 0 ]; then
        print_status "No errors detected during test"
    else
        print_warning "$error_count error(s) detected during test"
        print_info "Check full log: $temp_log"
    fi

    rm -f "$temp_log"
    echo ""
}

# Summary and recommendations
summary_and_recommendations() {
    print_header "RECOMMENDATIONS"

    echo "Based on the diagnostic results:"
    echo ""

    print_info "Optimal Setup:"
    echo "  1. Use robust scripts: ./start_gst_receiver_robust.sh"
    echo "  2. For SSH: ./ssh_pi_robust.sh"
    echo "  3. Expected performance: 25-30 fps"
    echo ""

    print_info "If experiencing issues:"
    echo "  1. Check network connectivity"
    echo "  2. Ensure Pi streamer is running"
    echo "  3. Verify all dependencies are installed"
    echo "  4. Check logs for specific error messages"
    echo ""

    print_info "Quick Start Commands:"
    echo "  ./start_streamer.sh          # Start Pi streamer"
    echo "  ./start_gst_receiver_robust.sh  # Start PC receiver"
    echo ""
}

# Main execution
main() {
    clear
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}    OAK-D Pro System Diagnostic${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""

    check_system_info
    check_dependencies
    check_gstreamer
    check_network
    check_ssh
    check_pi_status
    performance_test
    summary_and_recommendations

    echo -e "${CYAN}Diagnostic complete!${NC}"
}

# Run diagnostic
main "$@"