#!/bin/bash
# Setup internet sharing from PC to Pi for git operations
# PC shares WiFi internet connection to Pi via ethernet

echo "Setting up internet sharing: PC WiFi → Pi Ethernet"

# Enable IP forwarding
echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward > /dev/null

# Set up NAT masquerading (WiFi to internet)
sudo iptables -t nat -D POSTROUTING -o wlo1 -j MASQUERADE 2>/dev/null || true
sudo iptables -t nat -A POSTROUTING -o wlo1 -j MASQUERADE

# Set up forwarding rules
sudo iptables -D FORWARD -i eno2 -o wlo1 -j ACCEPT 2>/dev/null || true
sudo iptables -A FORWARD -i eno2 -o wlo1 -j ACCEPT

sudo iptables -D FORWARD -i wlo1 -o eno2 -m state --state RELATED,ESTABLISHED -j ACCEPT 2>/dev/null || true
sudo iptables -A FORWARD -i wlo1 -o eno2 -m state --state RELATED,ESTABLISHED -j ACCEPT

# Configure Pi to use PC as gateway
./ssh_pi_optimized.sh "sudo ip route del default via 192.168.1.1 dev eth0 2>/dev/null || true"
./ssh_pi_optimized.sh "sudo ip route del default via 192.168.1.50 dev eth0 2>/dev/null || true"
./ssh_pi_optimized.sh "sudo ip route add default via 192.168.1.50 dev eth0 metric 50"

# Set DNS on Pi
./ssh_pi_optimized.sh "echo 'nameserver 8.8.8.8' | sudo tee /etc/resolv.conf > /dev/null"

echo "✓ Internet sharing configured"
echo "✓ Pi can now access internet via PC (192.168.1.50 → WiFi)"
echo "✓ Pi will use ethernet (192.168.1.201) for both streaming and internet"