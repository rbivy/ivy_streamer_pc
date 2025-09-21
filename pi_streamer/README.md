# Pi Streamer

OAK-D Pro triple video streamer for Raspberry Pi.

## Setup on Raspberry Pi

1. **Install system dependencies:**
   ```bash
   sudo apt update
   sudo apt install python3-venv git
   ```

2. **Clone and setup:**
   ```bash
   git clone https://github.com/rbivy/ivy_streamer.git
   cd ivy_streamer/pi_streamer

   # Create virtual environment
   python3 -m venv venv
   source venv/bin/activate

   # Install dependencies
   pip install -r requirements.txt
   ```

3. **Run the streamer:**
   ```bash
   source venv/bin/activate
   python triple_streamer.py
   ```

## Quick Start Script

Use the convenience script:
```bash
./start_triple.sh
```

## Files
- `triple_streamer.py` - Main streaming application
- `start_triple.sh` - Automated startup script
- `requirements.txt` - Python dependencies
- `venv/` - Virtual environment (created locally, not in Git)