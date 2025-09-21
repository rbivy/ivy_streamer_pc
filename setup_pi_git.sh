#!/bin/bash
# Setup Git on Raspberry Pi for ivy_streamer

echo "========================================="
echo "  Setting up Git on Raspberry Pi"
echo "========================================="

# SSH to Pi and execute Git setup
ssh ivyspec@192.168.1.202 << 'ENDSSH'
# Configure Git
git config --global user.name "rbivy"
git config --global user.email "rbeech@ivyspec.com"

# Remove old directory if exists
cd /home/ivyspec
if [ -d "ivy_streamer_old" ]; then
    rm -rf ivy_streamer_old
fi

# Backup current directory
if [ -d "ivy_streamer" ]; then
    echo "Backing up current ivy_streamer directory..."
    mv ivy_streamer ivy_streamer_old
fi

# Clone repository (update token as needed)
echo "Cloning repository..."
echo "NOTE: Update the token in this script with your GitHub Personal Access Token"
# git clone https://rbivy:YOUR_TOKEN_HERE@github.com/rbivy/ivy_streamer.git

echo ""
echo "To complete setup:"
echo "1. Get a GitHub Personal Access Token"
echo "2. Update this script with the token"
echo "3. Uncomment and run the git clone command"
echo ""
echo "After cloning, set up the virtual environment:"
echo "cd ivy_streamer"
echo "python3 -m venv venv"
echo "source venv/bin/activate"
echo "pip install depthai numpy"

ENDSSH

echo "Git configuration complete on Pi"
echo "Follow the instructions above to complete the setup"