#!/bin/bash
  set -euo pipefail
  # set -e: exit if any command fails
  # set -u: exit if you use an undefined variable
  # set -o pipefail: catch errors in pipes like cmd1 | cmd2
LOG_FILE="/tmp/setup-$(date +%Y%m%d-%H%M%S).log"

log() {
  echo "[$(date '+%H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "Starting server setup..."

# ==============================================================================
# STEP 3 — Update the system
# ==============================================================================
log "Updating package lists..."
apt update -y

log "Upgrading installed software..."
apt upgrade -y
log "Packages completely updated!"

# ==============================================================================
# STEP 4 — Install core server dependencies
# ==============================================================================
# Define our packages inside a clean Bash Array
PACKAGES=(
  git
  curl
  vim
  htop
  wget
  unzip
  net-tools
)

log "📦 Installing useful tools: ${PACKAGES[*]}..."

# Install the array of packages cleanly
apt install -y "${PACKAGES[@]}"

log "✅ Core tools successfully installed!"

# ==============================================================================
# STEP 5 — Create a new non-root user
# ==============================================================================
NEW_USER="devopsuser"

# Check if the user already exists on this server
if id "$NEW_USER" &>/dev/null; then
  log "👤 User '$NEW_USER' already exists. Skipping user creation."
else
  log "👤 Creating new non-root system user: '$NEW_USER'..."
  
  # Create the user with a home directory and default bash shell
  useradd -m -s /bin/bash "$NEW_USER"
  
  # Add the user to the 'sudo' administrative group
  usermod -aG sudo "$NEW_USER"
  
  log "✅ Successfully created user '$NEW_USER' and added them to the sudo group."
fi
# ==============================================================================
# STEP 6 — Set the system timezone
# ==============================================================================
TARGET_TIMEZONE="Africa/Lagos"

log "⏰ Configuring system timezone to $TARGET_TIMEZONE..."

# Set the hardware/software clock timezone
timedatectl set-timezone "$TARGET_TIMEZONE"

# Extract the freshly updated active timezone name for verification
CURRENT_TZ=$(timedatectl | grep "Time zone" | awk '{print $3}')

log "✅ Timezone successfully updated. Current server time setting: $CURRENT_TZ"
# ==============================================================================
# STEP 7 — Enable basic firewall (UFW)
# ==============================================================================
log "🧱 Configuring UFW firewall security rules..."

# Rule 1: Block all incoming connection attempts by default
ufw default deny incoming

# Rule 2: Allow the server to make outgoing connections (e.g., download updates)
ufw default allow outgoing

# Rule 3: Open Port 22 explicitly so we don't lock ourselves out of SSH!
ufw allow ssh

# Rule 4: Turn on the firewall without popping up an interactive "Are you sure?" prompt
ufw --force enable

log "✅ UFW Firewall is now active and guarding your ports!"
# ==============================================================================
# STEP 8 — Print completion summary
# ==============================================================================
log "🎉 Server optimization and security hardening complete!"
log "💾 Full execution diary securely saved to: $LOG_FILE"

# Fetch the precise OS name and version from the system files
OS_VERSION=$(grep "PRETTY_NAME" /etc/os-release | cut -d'"' -f2)

echo ""
echo "===================================================="
echo "⚡ AUTOMATED SETUP SUMMARY"
echo "===================================================="
echo "  🖥️  Operating System : $OS_VERSION"
echo "  👤 Admin User Created: $NEW_USER"
echo "  ⏰ Configured Zone   : $TARGET_TIMEZONE"
echo "  🧱 Firewall Status  : ACTIVE (SSH Only)"
echo "===================================================="
echo ""