#!/usr/bin/env python3
"""
IMU Data Receiver for OAK-D Pro
Receives and displays real-time IMU data (accelerometer and gyroscope) via UDP
"""

import socket
import json
import time
import sys
import threading
from datetime import datetime
from collections import deque

class IMUReceiver:
    def __init__(self, pi_ip='192.168.1.201', port=5004):
        self.pi_ip = pi_ip
        self.port = port
        self.running = False
        self.sock = None
        self.data_history = deque(maxlen=100)  # Store last 100 readings
        self.last_update = None
        self.packet_count = 0
        self.start_time = None

    def connect(self):
        """Initialize UDP socket and register with the Pi streamer"""
        try:
            self.sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            self.sock.settimeout(1.0)

            # Send registration message to Pi
            print(f"Registering with IMU server at {self.pi_ip}:{self.port}...")
            self.sock.sendto(b'REGISTER_IMU', (self.pi_ip, self.port))

            # Wait for acknowledgment
            try:
                data, addr = self.sock.recvfrom(1024)
                if data == b'IMU_ACK':
                    print(f"✓ Successfully registered with IMU server")
                    return True
            except socket.timeout:
                print(f"✗ No response from IMU server. Make sure quad_streamer_with_imu.py is running on Pi")
                return False

        except Exception as e:
            print(f"✗ Failed to connect: {e}")
            return False

    def clear_screen(self):
        """Clear the terminal screen"""
        print('\033[2J\033[H', end='')

    def format_float(self, value, width=10, precision=4):
        """Format float with consistent width for alignment"""
        return f"{value:>{width}.{precision}f}"

    def display_data(self, imu_data):
        """Display IMU data in a formatted terminal view"""
        self.clear_screen()

        # Header
        print("=" * 70)
        print("              OAK-D Pro IMU Data Stream Monitor")
        print("=" * 70)

        # Connection info
        print(f"Connected to: {self.pi_ip}:{self.port}")
        print(f"Stream time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S.%f')[:-3]}")

        if self.start_time:
            elapsed = time.time() - self.start_time
            rate = self.packet_count / elapsed if elapsed > 0 else 0
            print(f"Packets: {self.packet_count} | Rate: {rate:.1f} Hz | Elapsed: {elapsed:.1f}s")

        print("-" * 70)

        # IMU Data
        timestamp = imu_data.get('timestamp', 0)
        accel = imu_data.get('accelerometer', {})
        gyro = imu_data.get('gyroscope', {})

        print(f"Timestamp: {timestamp:.6f} seconds")
        print("")

        # Accelerometer data (m/s²)
        print("ACCELEROMETER (m/s²):")
        print("  ┌─────────────────────────────────────────────────┐")
        print(f"  │  X: {self.format_float(accel.get('x', 0))} │ →    (Forward/Back)   │")
        print(f"  │  Y: {self.format_float(accel.get('y', 0))} │ ↑    (Left/Right)     │")
        print(f"  │  Z: {self.format_float(accel.get('z', 0))} │ ⊙    (Up/Down)        │")
        print("  └─────────────────────────────────────────────────┘")

        # Calculate magnitude
        ax, ay, az = accel.get('x', 0), accel.get('y', 0), accel.get('z', 0)
        accel_magnitude = (ax**2 + ay**2 + az**2)**0.5
        print(f"  Magnitude: {accel_magnitude:.4f} m/s²")
        print("")

        # Gyroscope data (rad/s)
        print("GYROSCOPE (rad/s):")
        print("  ┌─────────────────────────────────────────────────┐")
        print(f"  │  X: {self.format_float(gyro.get('x', 0))} │ ↻    (Pitch)          │")
        print(f"  │  Y: {self.format_float(gyro.get('y', 0))} │ ↺    (Yaw)            │")
        print(f"  │  Z: {self.format_float(gyro.get('z', 0))} │ ⟲    (Roll)           │")
        print("  └─────────────────────────────────────────────────┘")

        # Calculate magnitude
        gx, gy, gz = gyro.get('x', 0), gyro.get('y', 0), gyro.get('z', 0)
        gyro_magnitude = (gx**2 + gy**2 + gz**2)**0.5
        print(f"  Magnitude: {gyro_magnitude:.4f} rad/s")

        # Convert to degrees/s for readability
        print(f"  Degrees/s: X:{gx*57.2958:.2f}° Y:{gy*57.2958:.2f}° Z:{gz*57.2958:.2f}°")

        print("-" * 70)

        # Simple ASCII visualization of acceleration
        self.draw_accel_visualization(ax, ay, az)

        print("-" * 70)
        print("Press Ctrl+C to stop")

    def draw_accel_visualization(self, ax, ay, az):
        """Draw simple ASCII visualization of acceleration vector"""
        print("ACCELERATION VECTOR:")

        # Normalize for display (assuming ±20 m/s² range)
        max_val = 20.0
        norm_x = max(-1, min(1, ax / max_val))
        norm_y = max(-1, min(1, ay / max_val))
        norm_z = max(-1, min(1, az / max_val))

        # Create simple bar graphs
        def draw_bar(value, label, symbol='█'):
            width = 20
            center = width // 2
            pos = int(center + value * center)
            bar = [' '] * width
            bar[center] = '|'
            if pos != center:
                if pos > center:
                    for i in range(center+1, min(pos+1, width)):
                        bar[i] = symbol
                else:
                    for i in range(max(0, pos), center):
                        bar[i] = symbol
            return f"  {label}: [{''.join(bar)}] {value*max_val:6.2f}"

        print(draw_bar(norm_x, 'X'))
        print(draw_bar(norm_y, 'Y'))
        print(draw_bar(norm_z, 'Z'))

    def receive_loop(self):
        """Main loop to receive and display IMU data"""
        self.running = True
        self.start_time = time.time()

        while self.running:
            try:
                # Receive data
                data, addr = self.sock.recvfrom(4096)

                # Parse JSON data
                imu_data = json.loads(data.decode())

                # Update stats
                self.packet_count += 1
                self.last_update = time.time()
                self.data_history.append(imu_data)

                # Display data
                self.display_data(imu_data)

            except socket.timeout:
                # No data received, show waiting message
                if self.last_update and time.time() - self.last_update > 2:
                    self.clear_screen()
                    print("=" * 70)
                    print("              OAK-D Pro IMU Data Stream Monitor")
                    print("=" * 70)
                    print("⚠ Waiting for IMU data...")
                    print(f"Last update: {time.time() - self.last_update:.1f} seconds ago")
                    print("\nMake sure quad_streamer_with_imu.py is running on the Pi")
                    print("Press Ctrl+C to stop")

            except json.JSONDecodeError as e:
                print(f"✗ Failed to parse IMU data: {e}")

            except KeyboardInterrupt:
                break

            except Exception as e:
                print(f"✗ Error receiving data: {e}")
                time.sleep(0.1)

    def run(self):
        """Main entry point"""
        print("=" * 70)
        print("              OAK-D Pro IMU Data Receiver")
        print("=" * 70)
        print()

        if not self.connect():
            print("\n✗ Failed to connect to IMU server")
            print("Make sure:")
            print("  1. The Pi is accessible at", self.pi_ip)
            print("  2. quad_streamer_with_imu.py is running on the Pi")
            print("  3. Port", self.port, "is not blocked")
            return

        print("\nStarting IMU data reception...")
        print("Press Ctrl+C to stop\n")
        time.sleep(1)

        try:
            self.receive_loop()
        except KeyboardInterrupt:
            print("\n\nStopping IMU receiver...")
        finally:
            self.shutdown()

    def shutdown(self):
        """Clean shutdown"""
        self.running = False
        if self.sock:
            self.sock.close()
        print("IMU receiver stopped")
        print(f"Total packets received: {self.packet_count}")

if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description='OAK-D Pro IMU Data Receiver')
    parser.add_argument('--ip', default='192.168.1.202', help='Pi IP address (default: 192.168.1.202)')
    parser.add_argument('--port', type=int, default=5004, help='UDP port (default: 5004)')

    args = parser.parse_args()

    receiver = IMUReceiver(pi_ip=args.ip, port=args.port)
    receiver.run()