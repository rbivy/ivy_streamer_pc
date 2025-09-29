#!/usr/bin/env python3
"""
Simple window launcher for IMU data that doesn't rely on dbus
"""
import subprocess
import sys
import os
import tkinter as tk
from tkinter import scrolledtext
import threading
import queue
import json
import socket
import time

class IMUWindow:
    def __init__(self):
        self.root = tk.Tk()
        self.root.title("OAK-D Pro IMU Data Stream")
        self.root.geometry("800x600")
        self.root.configure(bg='black')

        # Create main frame
        main_frame = tk.Frame(self.root, bg='black')
        main_frame.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)

        # Title label
        title_label = tk.Label(main_frame, text="OAK-D Pro IMU Data Stream Monitor",
                              font=('Courier', 16, 'bold'), fg='lime', bg='black')
        title_label.pack(pady=(0, 10))

        # Status label
        self.status_label = tk.Label(main_frame, text="Connecting to 192.168.1.201:5004...",
                                   font=('Courier', 12), fg='yellow', bg='black')
        self.status_label.pack(pady=(0, 10))

        # Text display area
        self.text_area = scrolledtext.ScrolledText(main_frame,
                                                  font=('Courier', 10),
                                                  bg='black', fg='lime',
                                                  height=30, width=100)
        self.text_area.pack(fill=tk.BOTH, expand=True)

        # Data queue for thread communication
        self.data_queue = queue.Queue()

        # Start IMU receiver thread
        self.running = True
        self.receiver_thread = threading.Thread(target=self.receive_imu_data, daemon=True)
        self.receiver_thread.start()

        # Start display update loop
        self.update_display()

        # Handle window close
        self.root.protocol("WM_DELETE_WINDOW", self.on_closing)

    def receive_imu_data(self):
        """IMU data receiver thread"""
        sock = None
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            sock.settimeout(1.0)

            # Send registration message
            sock.sendto(b'REGISTER_IMU', ('192.168.1.201', 5004))

            # Wait for acknowledgment
            try:
                data, addr = sock.recvfrom(1024)
                if data == b'IMU_ACK':
                    self.data_queue.put(('status', 'Connected to IMU server'))
                else:
                    self.data_queue.put(('status', 'Connection failed'))
                    return
            except socket.timeout:
                self.data_queue.put(('status', 'No response from IMU server'))
                return

            packet_count = 0
            start_time = time.time()

            while self.running:
                try:
                    data, addr = sock.recvfrom(4096)
                    imu_data = json.loads(data.decode())
                    packet_count += 1

                    # Calculate rate
                    elapsed = time.time() - start_time
                    rate = packet_count / elapsed if elapsed > 0 else 0

                    # Add rate info to data
                    imu_data['_meta'] = {
                        'packet_count': packet_count,
                        'rate': rate,
                        'elapsed': elapsed
                    }

                    self.data_queue.put(('data', imu_data))

                except socket.timeout:
                    continue
                except json.JSONDecodeError:
                    continue
                except Exception as e:
                    self.data_queue.put(('error', str(e)))

        except Exception as e:
            self.data_queue.put(('error', f'Connection error: {e}'))
        finally:
            if sock:
                sock.close()

    def format_imu_display(self, imu_data):
        """Format IMU data for display"""
        meta = imu_data.get('_meta', {})
        timestamp = imu_data.get('timestamp', 0)
        accel = imu_data.get('accelerometer', {})
        gyro = imu_data.get('gyroscope', {})

        display_text = f"""
{'='*70}
Timestamp: {timestamp:.6f} seconds
Packets: {meta.get('packet_count', 0)} | Rate: {meta.get('rate', 0):.1f} Hz | Elapsed: {meta.get('elapsed', 0):.1f}s
{'='*70}

ACCELEROMETER (m/s²):
  X: {accel.get('x', 0):>10.4f}  →  (Forward/Back)
  Y: {accel.get('y', 0):>10.4f}  ↑  (Left/Right)
  Z: {accel.get('z', 0):>10.4f}  ⊙  (Up/Down)

GYROSCOPE (rad/s):
  X: {gyro.get('x', 0):>10.4f}  ↻  (Pitch)
  Y: {gyro.get('y', 0):>10.4f}  ↺  (Yaw)
  Z: {gyro.get('z', 0):>10.4f}  ⟲  (Roll)

GYROSCOPE (degrees/s):
  X: {gyro.get('x', 0)*57.2958:>8.2f}°
  Y: {gyro.get('y', 0)*57.2958:>8.2f}°
  Z: {gyro.get('z', 0)*57.2958:>8.2f}°

{'-'*70}
"""
        return display_text.strip()

    def update_display(self):
        """Update display with new data"""
        try:
            while not self.data_queue.empty():
                msg_type, data = self.data_queue.get_nowait()

                if msg_type == 'status':
                    self.status_label.config(text=data)

                elif msg_type == 'data':
                    display_text = self.format_imu_display(data)

                    # Clear and update text area
                    self.text_area.delete(1.0, tk.END)
                    self.text_area.insert(tk.END, display_text)

                    # Update status
                    meta = data.get('_meta', {})
                    status = f"Streaming at {meta.get('rate', 0):.1f} Hz | Packets: {meta.get('packet_count', 0)}"
                    self.status_label.config(text=status, fg='lime')

                elif msg_type == 'error':
                    self.status_label.config(text=f"Error: {data}", fg='red')

        except queue.Empty:
            pass

        # Schedule next update
        if self.running:
            self.root.after(50, self.update_display)

    def on_closing(self):
        """Handle window close"""
        self.running = False
        self.root.destroy()

    def run(self):
        """Start the GUI"""
        self.root.mainloop()

if __name__ == "__main__":
    app = IMUWindow()
    app.run()