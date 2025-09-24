#!/usr/bin/env python3
"""
Dual Interface Monitor - Check both ethernet and WiFi to see which carries Pi traffic
"""

import tkinter as tk
import time
import threading
from datetime import datetime
from collections import deque

class DualInterfaceMonitor:
    def __init__(self):
        self.root = tk.Tk()
        self.root.title("Dual Interface Bandwidth Monitor")
        self.root.geometry("700x500")

        self.running = True

        # Monitor both interfaces
        self.interfaces = {
            'eno2': {'name': 'Ethernet', 'prev_rx': 0, 'prev_tx': 0, 'history': deque(maxlen=15)},
            'wlo1': {'name': 'WiFi', 'prev_rx': 0, 'prev_tx': 0, 'history': deque(maxlen=15)}
        }

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

        threading.Thread(target=self.monitor_loop, daemon=True).start()

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

    def update_display(self, data):
        """Update display"""
        try:
            self.text.delete(1.0, tk.END)

            display_text = f"""
DUAL INTERFACE BANDWIDTH MONITOR
{datetime.now().strftime('%H:%M:%S')} - Which interface carries Pi streaming?
{'='*70}

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

            # Network configuration
            display_text += f"\nNETWORK CONFIGURATION:\n"
            display_text += f"Ethernet (eno2): 192.168.1.50/24\n"
            display_text += f"WiFi (wlo1):     192.168.1.233/24\n"
            display_text += f"Pi Target:       192.168.1.202\n"

            display_text += f"\n{'='*70}\n"
            display_text += "Monitoring both interfaces every 2 seconds\n"
            display_text += "This will show which interface actually carries your streaming data"

            self.text.insert(1.0, display_text)

            # Update status bar
            active_name = self.interfaces[active_interface]['name'] if active_interface else 'Unknown'
            self.status.config(text=f"Active: {active_name} | System Total: {total_system_mbps:.2f} Mbps | Samples: {len(self.interfaces['eno2']['history'])}")

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