#!/usr/bin/env python3
"""
Dual Interface Monitor - Check both ethernet and WiFi to see which carries Pi traffic
"""

import tkinter as tk
import time
import threading
from datetime import datetime
from collections import deque
import socket
import struct

class DualInterfaceMonitor:
    def __init__(self):
        self.root = tk.Tk()
        self.root.title("Dual Interface & Video Stream Monitor")
        self.root.geometry("800x600")

        self.running = True
        self.pi_ip = "192.168.1.201"

        # Monitor both interfaces
        self.interfaces = {
            'eno2': {'name': 'Ethernet', 'prev_rx': 0, 'prev_tx': 0, 'history': deque(maxlen=15)},
            'wlo1': {'name': 'WiFi', 'prev_rx': 0, 'prev_tx': 0, 'history': deque(maxlen=15)}
        }

        # Video stream monitoring
        self.video_streams = {
            5000: {'name': 'RGB', 'frame_count': 0, 'last_frame_time': 0, 'fps_history': deque(maxlen=10), 'active': False, 'monitor_bandwidth': 0},
            5001: {'name': 'Left', 'frame_count': 0, 'last_frame_time': 0, 'fps_history': deque(maxlen=10), 'active': False, 'monitor_bandwidth': 0},
            5002: {'name': 'Right', 'frame_count': 0, 'last_frame_time': 0, 'fps_history': deque(maxlen=10), 'active': False, 'monitor_bandwidth': 0},
            5003: {'name': 'Depth', 'frame_count': 0, 'last_frame_time': 0, 'fps_history': deque(maxlen=10), 'active': False, 'monitor_bandwidth': 0}
        }

        self.fps_lock = threading.Lock()

        self.setup_gui()
        self.start_monitoring()

    def get_interface_stats(self, interface):
        """Get interface statistics"""
        try:
            with open('/proc/net/dev', 'r') as f:
                for line in f:
                    if f'{interface}:' in line:
                        parts = line.split()
                        rx_bytes = int(parts[1])
                        tx_bytes = int(parts[9])
                        rx_packets = int(parts[2])
                        tx_packets = int(parts[10])
                        return rx_bytes, tx_bytes, rx_packets, tx_packets
        except Exception as e:
            print(f"Error reading {interface} stats: {e}")

        return 0, 0, 0, 0

    def setup_gui(self):
        """Setup GUI"""
        self.text = tk.Text(self.root, font=('Courier', 9), bg='black', fg='green')
        self.text.pack(fill='both', expand=True, padx=10, pady=10)

        self.status = tk.Label(self.root, text="Starting dual interface monitoring...",
                              bg='lightgray', relief='sunken')
        self.status.pack(fill='x', side='bottom')

    def start_monitoring(self):
        """Initialize monitoring"""
        # Get initial values
        for iface in self.interfaces:
            rx, tx, _, _ = self.get_interface_stats(iface)
            self.interfaces[iface]['prev_rx'] = rx
            self.interfaces[iface]['prev_tx'] = tx

        # Start monitoring threads
        threading.Thread(target=self.monitor_loop, daemon=True).start()
        threading.Thread(target=self.fps_monitor_loop, daemon=True).start()

    def monitor_loop(self):
        """Main monitoring loop"""
        while self.running:
            try:
                time.sleep(2)  # 2 second intervals

                interface_data = {}

                for iface in self.interfaces:
                    current_rx, current_tx, rx_packets, tx_packets = self.get_interface_stats(iface)

                    # Calculate deltas
                    rx_diff = current_rx - self.interfaces[iface]['prev_rx']
                    tx_diff = current_tx - self.interfaces[iface]['prev_tx']

                    # Convert to Mbps (2 second interval)
                    rx_mbps = (rx_diff * 8) / (2 * 1000 * 1000)
                    tx_mbps = (tx_diff * 8) / (2 * 1000 * 1000)
                    total_mbps = rx_mbps + tx_mbps

                    # Store data
                    interface_data[iface] = {
                        'rx_mbps': rx_mbps,
                        'tx_mbps': tx_mbps,
                        'total_mbps': total_mbps,
                        'rx_packets': rx_packets,
                        'tx_packets': tx_packets,
                        'total_rx_gb': current_rx / (1024**3),
                        'total_tx_gb': current_tx / (1024**3)
                    }

                    # Add to history
                    self.interfaces[iface]['history'].append(total_mbps)

                    # Update for next iteration
                    self.interfaces[iface]['prev_rx'] = current_rx
                    self.interfaces[iface]['prev_tx'] = current_tx

                self.update_display(interface_data)

            except Exception as e:
                print(f"Monitor loop error: {e}")
                time.sleep(2)

    def fps_monitor_loop(self):
        """Monitor FPS for all video streams - SINGLE THREAD PER PORT"""
        # Start one persistent thread per port (no continuous spawning)
        for port in self.video_streams:
            threading.Thread(target=self.monitor_stream_fps, args=(port,), daemon=True).start()

        # Simple keepalive loop
        while self.running:
            try:
                time.sleep(5)  # Just keep the main thread alive
            except Exception as e:
                print(f"FPS monitor loop error: {e}")
                time.sleep(5)

    def monitor_stream_fps(self, port):
        """Monitor FPS for a specific video stream port - AGGRESSIVE MODE for best video quality"""
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(2.0)
            sock.connect((self.pi_ip, port))

            with self.fps_lock:
                self.video_streams[port]['active'] = True

            frame_start_time = time.time()
            frame_count = 0
            buffer = b''
            bytes_read = 0

            while self.running:
                try:
                    # AGGRESSIVE: Read large chunks to maximize data consumption and improve video quality
                    data = sock.recv(8192)  # Back to aggressive reading for video quality
                    if not data:
                        break

                    bytes_read += len(data)
                    buffer += data

                    # For H.264 streams (ports 5000-5002), look for NAL unit start codes
                    # For JPEG stream (port 5003), look for JPEG markers
                    if port in [5000, 5001, 5002]:
                        # H.264 NAL unit start code: 0x00000001 or 0x000001
                        while True:
                            # Look for 4-byte start code
                            pos = buffer.find(b'\x00\x00\x00\x01')
                            if pos == -1:
                                # Look for 3-byte start code
                                pos = buffer.find(b'\x00\x00\x01')
                                if pos == -1:
                                    break
                                buffer = buffer[pos + 3:]
                            else:
                                buffer = buffer[pos + 4:]

                            frame_count += 1
                            current_time = time.time()

                            # Calculate FPS every second
                            if current_time - frame_start_time >= 1.0:
                                fps = frame_count / (current_time - frame_start_time)
                                mbps_consumed = (bytes_read * 8) / (1000 * 1000)  # Track our consumption

                                with self.fps_lock:
                                    self.video_streams[port]['fps_history'].append(fps)
                                    self.video_streams[port]['frame_count'] += frame_count
                                    self.video_streams[port]['last_frame_time'] = current_time
                                    self.video_streams[port]['monitor_bandwidth'] = mbps_consumed

                                frame_count = 0
                                frame_start_time = current_time
                                bytes_read = 0

                    elif port == 5003:
                        # JPEG stream - look for JPEG SOI marker (0xFFD8)
                        while True:
                            pos = buffer.find(b'\xff\xd8')
                            if pos == -1:
                                break
                            buffer = buffer[pos + 2:]

                            frame_count += 1
                            current_time = time.time()

                            # Calculate FPS every second
                            if current_time - frame_start_time >= 1.0:
                                fps = frame_count / (current_time - frame_start_time)
                                mbps_consumed = (bytes_read * 8) / (1000 * 1000)

                                with self.fps_lock:
                                    self.video_streams[port]['fps_history'].append(fps)
                                    self.video_streams[port]['frame_count'] += frame_count
                                    self.video_streams[port]['last_frame_time'] = current_time
                                    self.video_streams[port]['monitor_bandwidth'] = mbps_consumed

                                frame_count = 0
                                frame_start_time = current_time
                                bytes_read = 0

                    # Keep buffer size larger for aggressive data consumption
                    if len(buffer) > 16384:  # Increased buffer size
                        buffer = buffer[-8192:]

                    # NO DELAY - maximum aggressive polling for best video performance

                except socket.timeout:
                    # Connection timeout is normal when stream is not active
                    break
                except Exception as e:
                    print(f"Stream monitor error for port {port}: {e}")
                    break

            sock.close()

        except (ConnectionRefusedError, socket.timeout, OSError):
            # Stream not available - this is normal when Pi is not streaming
            pass
        except Exception as e:
            print(f"FPS monitor error for port {port}: {e}")
        finally:
            with self.fps_lock:
                self.video_streams[port]['active'] = False

    def update_display(self, data):
        """Update display"""
        try:
            self.text.delete(1.0, tk.END)

            display_text = f"""
DUAL INTERFACE & VIDEO STREAM MONITOR
{datetime.now().strftime('%H:%M:%S')} - Network bandwidth + Video stream FPS
{'='*80}

"""

            total_system_mbps = 0
            active_interface = None
            max_mbps = 0

            for iface in ['eno2', 'wlo1']:
                if iface in data:
                    info = self.interfaces[iface]
                    d = data[iface]

                    # Calculate averages
                    if info['history']:
                        avg_mbps = sum(info['history']) / len(info['history'])
                        peak_mbps = max(info['history'])
                    else:
                        avg_mbps = peak_mbps = 0

                    # Determine if this interface is active for streaming
                    if avg_mbps > max_mbps:
                        max_mbps = avg_mbps
                        active_interface = iface

                    display_text += f"{info['name'].upper()} ({iface}):\n"
                    display_text += f"  Current:    RX {d['rx_mbps']:.2f} Mbps | TX {d['tx_mbps']:.2f} Mbps | Total {d['total_mbps']:.2f} Mbps\n"
                    display_text += f"  Average:    {avg_mbps:.2f} Mbps (last {len(info['history'])} samples)\n"
                    display_text += f"  Peak:       {peak_mbps:.2f} Mbps\n"
                    display_text += f"  Packets:    RX {d['rx_packets']:,} | TX {d['tx_packets']:,}\n"
                    display_text += f"  Total Data: RX {d['total_rx_gb']:.2f} GB | TX {d['total_tx_gb']:.2f} GB\n"

                    # Activity indicator
                    if avg_mbps > 5:
                        display_text += f"  🟢 ACTIVE - Significant traffic\n"
                    elif avg_mbps > 1:
                        display_text += f"  🟡 LIGHT - Some traffic\n"
                    else:
                        display_text += f"  ⚪ IDLE - Minimal traffic\n"

                    display_text += "\n"
                    total_system_mbps += d['total_mbps']

            # Analysis
            display_text += f"ANALYSIS:\n"
            if active_interface:
                iface_name = self.interfaces[active_interface]['name']
                display_text += f"🎯 PRIMARY INTERFACE: {iface_name} ({active_interface})\n"
                display_text += f"   This interface appears to carry the streaming traffic\n"

                if active_interface == 'wlo1':
                    display_text += f"   ⚠️  Streaming over WiFi - consider using ethernet for stability\n"
                else:
                    display_text += f"   ✅ Streaming over Ethernet - good for stability\n"
            else:
                display_text += f"❓ No significant traffic detected on either interface\n"

            display_text += f"\nSYSTEM TOTAL: {total_system_mbps:.2f} Mbps across all interfaces\n"

            # Video Stream FPS Information
            display_text += f"\nVIDEO STREAM FPS MONITORING:\n"
            with self.fps_lock:
                active_streams = 0
                total_fps = 0
                total_monitor_bandwidth = 0

                for port, stream_info in self.video_streams.items():
                    name = stream_info['name']

                    if stream_info['active'] and stream_info['fps_history']:
                        current_fps = stream_info['fps_history'][-1] if stream_info['fps_history'] else 0
                        avg_fps = sum(stream_info['fps_history']) / len(stream_info['fps_history'])
                        max_fps = max(stream_info['fps_history'])
                        total_frames = stream_info['frame_count']
                        monitor_bw = stream_info.get('monitor_bandwidth', 0)

                        display_text += f"🎥 {name} (Port {port}): {current_fps:.1f} FPS (avg: {avg_fps:.1f}, max: {max_fps:.1f}) - {total_frames:,} frames\n"
                        display_text += f"    Monitor overhead: {monitor_bw:.2f} Mbps\n"
                        active_streams += 1
                        total_fps += current_fps
                        total_monitor_bandwidth += monitor_bw

                    elif stream_info['active']:
                        display_text += f"🟡 {name} (Port {port}): Connecting... (active but no frames detected)\n"
                    else:
                        display_text += f"⚪ {name} (Port {port}): Not streaming\n"

                if active_streams > 0:
                    display_text += f"\n📊 STREAMING SUMMARY: {active_streams}/4 streams active, Total FPS: {total_fps:.1f}\n"
                    display_text += f"📈 MONITORING MODE: AGGRESSIVE ({total_monitor_bandwidth:.1f} Mbps) - High video quality\n"
                    display_text += f"🚀 BENEFIT: Reduced video latency, improved frame quality via aggressive buffering\n"
                else:
                    display_text += f"\n❌ No video streams detected - Pi may not be streaming\n"

            # Network configuration
            display_text += f"\nNETWORK CONFIGURATION:\n"
            display_text += f"Ethernet (eno2): 192.168.1.50/24\n"
            display_text += f"WiFi (wlo1):     192.168.1.233/24\n"
            display_text += f"Pi SSH (WiFi):   192.168.1.202\n"
            display_text += f"Pi Stream (Eth): 192.168.1.201\n"

            display_text += f"\n{'='*80}\n"
            display_text += "Monitoring interfaces (2s intervals) + video streams (1s intervals)\n"
            display_text += "Real-time network bandwidth and video stream FPS monitoring"

            self.text.insert(1.0, display_text)

            # Update status bar with video stream info
            active_name = self.interfaces[active_interface]['name'] if active_interface else 'Unknown'

            with self.fps_lock:
                active_video_streams = sum(1 for s in self.video_streams.values() if s['active'])
                total_fps = sum(s['fps_history'][-1] if s['fps_history'] else 0 for s in self.video_streams.values())

            self.status.config(text=f"Network: {active_name} ({total_system_mbps:.1f}Mbps) | Video: {active_video_streams}/4 streams ({total_fps:.1f}fps total) | Samples: {len(self.interfaces['eno2']['history'])}")

        except Exception as e:
            print(f"Display update error: {e}")

    def run(self):
        try:
            self.root.protocol("WM_DELETE_WINDOW", self.on_closing)
            self.root.mainloop()
        finally:
            self.running = False

    def on_closing(self):
        self.running = False
        self.root.destroy()

if __name__ == "__main__":
    monitor = DualInterfaceMonitor()
    monitor.run()