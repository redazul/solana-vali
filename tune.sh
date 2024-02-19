#!/bin/bash

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi

# Optimize sysctl settings for Solana validator
echo "Configuring sysctl settings for Solana validator..."
cat >/etc/sysctl.d/21-solana-validator.conf <<EOF
# Increase UDP buffer sizes
net.core.rmem_default = 134217728
net.core.rmem_max = 134217728
net.core.wmem_default = 134217728
net.core.wmem_max = 134217728

# Increase memory mapped files limit
vm.max_map_count = 1000000

# Increase number of allowed open file descriptors
fs.nr_open = 1000000
EOF

# Apply sysctl settings without reboot
sysctl -p /etc/sysctl.d/21-solana-validator.conf

# Increase systemd file limits
echo "Updating systemd service file limits..."
# Add or modify DefaultLimitNOFILE for system-wide limit
sed -i '/DefaultLimitNOFILE=/c\DefaultLimitNOFILE=1000000' /etc/systemd/system.conf || echo "DefaultLimitNOFILE=1000000" >> /etc/systemd/system.conf

# Reload systemd manager configuration to apply changes
systemctl daemon-reload

# Increase security limits for file descriptors
echo "Setting security limits for file descriptors..."
cat >/etc/security/limits.d/90-solana-nofiles.conf <<EOF
# Increase process file descriptor count limit
* - nofile 1000000
EOF

echo "System tuning for Solana validator completed."
echo "Please close all open sessions and log in again to apply changes."
