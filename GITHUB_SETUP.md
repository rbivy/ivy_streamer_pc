# GitHub Setup Instructions

## Manual Steps Required

GitHub requires Personal Access Token (PAT) or SSH authentication. Password authentication is no longer supported.

### Option 1: Personal Access Token (Recommended)

1. **Create a Personal Access Token on GitHub:**
   - Go to GitHub.com and log in as `rbivy`
   - Go to Settings → Developer settings → Personal access tokens → Tokens (classic)
   - Click "Generate new token (classic)"
   - Give it a name like "ivy_streamer"
   - Select scopes: `repo` (full control)
   - Generate and copy the token

2. **Update the remote URL with token:**
   ```bash
   git remote set-url origin https://rbivy:YOUR_TOKEN_HERE@github.com/rbivy/ivy_streamer.git
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
   git remote set-url origin git@github.com:rbivy/ivy_streamer.git
   git push -u origin main
   ```

## For Raspberry Pi

After pushing from PC, on the Raspberry Pi:

```bash
# Remove old directory
cd /home/ivyspec
rm -rf ivy_streamer

# Clone with credentials
git clone https://rbivy:YOUR_TOKEN_HERE@github.com/rbivy/ivy_streamer.git

# Or with SSH
git clone git@github.com:rbivy/ivy_streamer.git

# Set up virtual environment
cd ivy_streamer
python3 -m venv venv
source venv/bin/activate
pip install depthai numpy
```

## Repository Information
- **User:** rbivy
- **Email:** rbeech@ivyspec.com
- **Repository:** ivy_streamer
- **Description:** OAK-D Pro triple video streamer for Raspberry Pi

## Current Status
- ✅ Local Git repository initialized
- ✅ Initial commit created
- ⏳ Awaiting GitHub authentication setup
- ⏳ Ready to push once authentication is configured