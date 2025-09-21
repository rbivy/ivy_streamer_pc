# Scripts

Utility scripts for managing the ivy_streamer system.

## Files

### SSH and Remote Management
- `ssh_pi_robust.sh` - Robust SSH connection script with error handling
- `setup_pi_git.sh` - Git setup script for Raspberry Pi

### System Diagnostics
- `system_diagnostic.sh` - Comprehensive system health check

## Usage

All scripts are executable. Run them from the project root directory:

```bash
# Connect to Pi
./scripts/ssh_pi_robust.sh

# Run command on Pi
./scripts/ssh_pi_robust.sh "command here"

# System diagnostics
./scripts/system_diagnostic.sh
```