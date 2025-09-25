#!/bin/bash

# Optimized SSH script for Raspberry Pi OAK-D Pro project
# Uses SSH key authentication and connection multiplexing for speed

PROJECT_DIR="/home/ivyspec/ivy_streamer"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${GREEN}✓${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1"; }
print_warning() { echo -e "${YELLOW}⚠${NC} $1"; }
print_info() { echo -e "${BLUE}ℹ${NC} $1"; }

# Quick connectivity check
check_pi_connection() {
    if ! ping -c 1 -W 2 192.168.1.202 &>/dev/null; then
        print_error "Pi not reachable at 192.168.1.202"
        return 1
    fi
    return 0
}

# Fast SSH execution with key auth
execute_ssh() {
    local max_retries=2
    local retry_count=0

    while [ $retry_count -lt $max_retries ]; do
        if ssh -o ConnectTimeout=5 pi "cd $PROJECT_DIR 2>/dev/null; $*" 2>/dev/null; then
            return 0
        fi

        retry_count=$((retry_count + 1))
        if [ $retry_count -lt $max_retries ]; then
            print_warning "SSH attempt $retry_count failed, retrying..."
            sleep 0.5
        fi
    done

    print_error "SSH failed after $max_retries attempts"
    return 1
}

main() {
    if [ $# -eq 0 ]; then
        # Interactive session
        print_info "Connecting to Pi (interactive)..."
        ssh pi -t "cd $PROJECT_DIR 2>/dev/null || echo 'Warning: Project directory not found'; exec bash -l"
    else
        # Execute command
        if ! check_pi_connection; then
            exit 1
        fi

        if execute_ssh "$@"; then
            print_status "Command executed successfully"
        else
            print_error "Command execution failed"
            exit 1
        fi
    fi
}

# Run without strict error checking
main "$@"