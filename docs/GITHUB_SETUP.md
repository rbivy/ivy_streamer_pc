# GitHub Setup Instructions - PC Receivers Repository

## Repository Information
- **PC Repository**: https://github.com/rbivy/ivy_streamer_pc
- **Pi Repository**: https://github.com/rbivy/ivy_streamer_pi (separate)
- **User**: rbivy
- **Email**: rbeech@ivyspec.com

## Manual Steps Required

GitHub requires Personal Access Token (PAT) or SSH authentication. Password authentication is no longer supported.

### Option 1: Personal Access Token (Recommended)

1. **Create a Personal Access Token on GitHub:**
   - Go to GitHub.com and log in as `rbivy`
   - Go to Settings → Developer settings → Personal access tokens → Tokens (classic)
   - Click "Generate new token (classic)"
   - Give it a name like "ivy_streamer_pc"
   - Select scopes: `repo` (full control)
   - Generate and copy the token

2. **Update the remote URL with token:**
   ```bash
   git remote set-url origin https://rbivy:YOUR_TOKEN_HERE@github.com/rbivy/ivy_streamer_pc.git
   ```

3. **Push the code:**
   ```bash
   git push -u origin main
   ```

### Option 2: SSH Key

1. **Generate SSH key (if not existing):**
   ```bash
   ssh-keygen -t ed25519 -C "rbeech@ivyspec.com"
   ```

2. **Add SSH key to GitHub:**
   - Copy the public key: `cat ~/.ssh/id_ed25519.pub`
   - Go to GitHub Settings → SSH and GPG keys
   - Add new SSH key

3. **Change remote to SSH:**
   ```bash
   git remote set-url origin git@github.com:rbivy/ivy_streamer_pc.git
   git push -u origin main
   ```

## For Raspberry Pi (Separate Repository)

The Pi side has its own separate repository. After setting up PC repository:

```bash
# On Pi - clone the Pi-specific repository
cd /home/ivyspec
git clone https://rbivy:YOUR_TOKEN_HERE@github.com/rbivy/ivy_streamer_pi.git ivy_streamer

# Or with SSH
git clone git@github.com:rbivy/ivy_streamer_pi.git ivy_streamer

# Set up virtual environment (Pi side only)
cd ivy_streamer
python3 -m venv venv
source venv/bin/activate
pip install depthai numpy
```

## Repository Descriptions
- **PC Repository (this one)**: OAK-D Pro GStreamer receivers for PC
- **Pi Repository (separate)**: OAK-D Pro Python streamers for Raspberry Pi

## Current Status
- ✅ PC-only architecture implemented
- ✅ GStreamer-based receivers
- ✅ Automatic cleanup and startup scripts
- ⏳ Ready to push to GitHub once authentication is configured