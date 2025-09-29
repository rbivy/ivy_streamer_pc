# GEMINI.md

## Project Overview

This project is a high-performance, low-latency video and IMU data streaming system. It is designed to stream data from an OAK-D Pro camera connected to a Raspberry Pi 5 to a PC for computer vision applications.

The system streams four video feeds (RGB, left mono, right mono, and depth) and IMU data (accelerometer and gyroscope) over a dedicated ethernet connection. A separate WiFi connection is used for control and SSH access. The PC-side application receives and displays the data in real-time, with dedicated windows for each video stream, IMU data, and network/performance monitoring.

**This repository contains the PC-side application, which is built using GStreamer and shell scripts. The Raspberry Pi-side streamer is in a separate repository.**

**Key Technologies:**

*   **Hardware:** Raspberry Pi 5, OAK-D Pro camera
*   **Software (PC):** GStreamer, Shell Scripts
*   **Software (Pi):** Python, DepthAI
*   **Networking:** TCP for video streams, UDP for IMU data

## Building and Running

### Dependencies (PC)

**System:**
*   `gstreamer1.0-tools`
*   `gstreamer1.0-plugins-base`
*   `gstreamer1.0-plugins-good`
*   `gstreamer1.0-plugins-bad`
*   `python3-tk` (for the IMU and monitoring GUI)

Install with:
```bash
sudo apt install gstreamer1.0-tools gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-bad python3-tk
```

**No Python virtual environment is needed on the PC side.**

### Running the System

The main script to start the entire system is `start_quad_with_imu_optimized.sh`. This script handles:
1.  Stopping any previous streamer processes on the Raspberry Pi.
2.  Starting the streamer script on the Raspberry Pi via SSH.
3.  Verifying that the streams are available.
4.  Launching the PC-side receiver applications.

To run the system:
```bash
./start_quad_with_imu_optimized.sh
```

This will open six windows:
*   Four video stream windows (RGB, Left, Right, Depth)
*   One IMU data visualization window
*   One network and performance monitoring window

## Development Conventions

*   The project is split into two repositories:
    *   **PC-side (this one):** GStreamer-based receivers and control scripts.
    *   **Pi-side:** Python-based streamer using the DepthAI library.
*   Shell scripts are used extensively to orchestrate the system.
*   The PC-side application uses GStreamer for video and `tkinter` for the IMU and monitoring GUIs.
*   The `dual_interface_monitor.py` script provides a comprehensive overview of the system's performance, including network bandwidth and video stream FPS.
*   The `imu_receiver.py` and `launch_imu_window.py` scripts are responsible for handling the IMU data stream.
*   The `ARCHITECTURE.md` file provides a detailed diagram and explanation of the system's architecture.
*   The `README.md` and `docs/FUTURE_SELF_GUIDE.md` files contain detailed setup and usage instructions.