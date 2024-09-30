#!/bin/bash

# Define backup directory
BACKUP_DIR="/opt/backup_$(date +%Y%m%d%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Backup 'ip link show vmbr0' output
VM_BRIDGE_MAC=$(ip link show vmbr0 | grep link/ether | awk '{print $2}')
echo "MAC Address for vmbr0: $VM_BRIDGE_MAC" > "$BACKUP_DIR/vmbr0_mac.txt"

# Backup /etc/network/interfaces
cp /etc/network/interfaces "$BACKUP_DIR/interfaces_backup"

# Backup /etc/resolv.conf
cp /etc/resolv.conf "$BACKUP_DIR/resolv.conf_backup"

# Backup /opt/ggrock/app/App_Data/config.json
cp /opt/ggrock/app/App_Data/config.json "$BACKUP_DIR/config.json_backup"

# Backup /etc/dnsmasq.d/vlan.conf
cp /etc/dnsmasq.d/vlan.conf "$BACKUP_DIR/vlan.conf_backup"

# Notify completion
echo "Backup completed. All files are saved in $BACKUP_DIR"
