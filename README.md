# OAK-D Pro PC Receivers

GStreamer-based video receivers with advanced overlays for the OAK-D Pro triple video streams.

## Quick Setup

```bash
# Clone this repository
git clone https://github.com/rbivy/ivy_streamer_pc.git
cd ivy_streamer_pc

# Install GStreamer (Ubuntu/Debian)
sudo apt install gstreamer1.0-tools gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-bad

# Make scripts executable
chmod +x *.sh

# Start receiving video (Pi must be streaming first)
./test_triple_advanced_overlay.sh
```

## Receiver Scripts

### Advanced Overlays (Recommended)
```bash
./test_triple_advanced_overlay.sh
```
Shows:
- Stream name and resolution (top left)
- Current timestamp (top right)
- Real-time FPS counter (bottom)
- Status monitoring every 5 seconds

### Basic Overlays
```bash
./test_triple_overlay.sh
```
Shows:
- FPS counter only

### Simple Receivers
```bash
./test_triple.sh
```
No overlays, minimal CPU usage

## Utility Scripts

### SSH and Pi Management
```bash
# Connect to Pi
./ssh_pi_robust.sh

# Run command on Pi
./ssh_pi_robust.sh "command here"

# System diagnostics
./system_diagnostic.sh
```

### Git Setup for Pi
```bash
# Setup Git on Pi (update token first)
./setup_pi_git.sh
```

## Network Requirements

- Pi streaming on ports 5000, 5001, 5002
- Same network as Raspberry Pi
- ~14 Mbps bandwidth for full resolution
- GStreamer installed on PC

## Features

- **Triple simultaneous streams**: RGB + Left + Right cameras
- **Real-time overlays**: FPS, resolution, timestamp
- **Status monitoring**: Process health checking
- **Flexible display**: Multiple overlay options
- **Pi management**: SSH and remote control tools

## Files

- `test_triple_advanced_overlay.sh` - Advanced receiver with full telemetry
- `test_triple_overlay.sh` - Basic FPS overlay receiver
- `test_triple.sh` - Simple receiver without overlays
- `ssh_pi_robust.sh` - Robust SSH connection script
- `system_diagnostic.sh` - System health check
- `setup_pi_git.sh` - Pi Git setup helper
- `docs/` - Additional documentation