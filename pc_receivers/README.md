# PC Receivers

GStreamer-based video receivers for the OAK-D Pro triple streams.

## Setup on PC

1. **Install GStreamer:**
   ```bash
   # Ubuntu/Debian
   sudo apt install gstreamer1.0-tools gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-bad

   # Or check requirements.txt for details
   ```

2. **Make scripts executable:**
   ```bash
   chmod +x *.sh
   ```

## Usage

### All Three Streams with Overlays (Recommended)
```bash
./test_triple_advanced_overlay.sh
```

### Basic Overlays
```bash
./test_triple_overlay.sh
```

### Simple Streams (No Overlays)
```bash
./test_triple.sh
```

## Features
- Real-time FPS display
- Stream information overlays
- Timestamp overlays
- Individual stream control

## Files
- `test_triple_advanced_overlay.sh` - Advanced overlays with monitoring
- `test_triple_overlay.sh` - Basic FPS overlays
- `test_triple.sh` - Simple receivers without overlays