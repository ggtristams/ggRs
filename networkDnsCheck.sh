#!/bin/bash

# Paths to the configuration files
INTERFACES_CONFIG_FILE="/etc/network/interfaces"
RESOLV_CONF_FILE="/etc/resolv.conf"

# Get the current IP addresses and interface states
CURRENT_STATUS=$(ip a)

# Function to extract interface details from config file
parse_interfaces_config() {
  awk '
  BEGIN { iface="" }
  /^auto/ {
    if (NF < 2) {
      print "Syntax error: missing interface name after auto"
    }
  }
  /^iface/ {
    iface=$2
    method=$4
    if (NF < 4) {
      print "Syntax error: missing method for interface " iface
    }
  }
  /^address/ && iface {
    if (!($2 ~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/)) {
      print "Invalid IP address format for interface " iface ": " $2
    }
    address=$2
  }
  /^netmask/ && iface {
    if (!($2 ~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/)) {
      print "Invalid netmask format for interface " iface ": " $2
    }
    netmask=$2
  }
  /^gateway/ && iface {
    if (!($2 ~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/)) {
      print "Invalid gateway format for interface " iface ": " $2
    }
    gateway=$2
  }
  /^bridge_ports/ && iface {
    bridge_ports=$2
  }
  /^bridge_fd/ && iface {
    if (!($2 ~ /^[0-9]+$/)) {
      print "Invalid bridge_fd value for interface " iface ": " $2
    }
    bridge_fd=$2
  }
  /^bridge_stp/ && iface {
    if ($2 != "on" && $2 != "off") {
      print "Invalid bridge_stp value for interface " iface ": " $2
    }
    bridge_stp=$2
  }
  /^$/ {
    if (iface) {
      print iface, method, address, netmask, gateway, bridge_ports, bridge_fd, bridge_stp
      iface=""
      method=""
      address=""
      netmask=""
      gateway=""
      bridge_ports=""
      bridge_fd=""
      bridge_stp=""
    }
  }
  END {
    if (iface) {
      print iface, method, address, netmask, gateway, bridge_ports, bridge_fd, bridge_stp
    }
  }
  ' "$INTERFACES_CONFIG_FILE"
}

# Function to extract current interface details from ip a
parse_current_status() {
  echo "$CURRENT_STATUS" | awk '
  /^(.*):/ { iface=$2 }
  /inet / && iface {
    split($2, a, "/")
    address=a[1]
  }
  /inet6 / && iface {
    split($2, a, "/")
    address6=a[1]
  }
  /state / && iface {
    state=$9
  }
  /^$/ {
    if (iface) {
      print iface, address, address6, state
      iface=""
      address=""
      address6=""
      state=""
    }
  }
  END {
    if (iface) {
      print iface, address, address6, state
    }
  }
  '
}

# Function to extract DNS details from resolv.conf
parse_resolv_conf() {
  awk '
  /^nameserver/ {
    if (!($2 ~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/)) {
      print "Invalid nameserver IP address: " $2
    }
    print "Nameserver: " $2
  }
  ' "$RESOLV_CONF_FILE"
}

# Compare the configurations
compare_configs() {
  echo "==============================================="

  echo "Checking network configuration discrepancies..."

  config=$(parse_interfaces_config)
  current=$(parse_current_status)

  echo "Configured interfaces:"
  echo "$config"
  echo
  echo "Current interface status:"
  echo "$current"
  echo

  while IFS= read -r line; do
    iface=$(echo "$line" | awk '{print $1}')
    method=$(echo "$line" | awk '{print $2}')
    address=$(echo "$line" | awk '{print $3}')
    netmask=$(echo "$line" | awk '{print $4}')
    gateway=$(echo "$line" | awk '{print $5}')

    current_line=$(echo "$current" | grep -w "$iface")

    if [ -z "$current_line" ]; then
      echo "Interface $iface is not found in current status!"
      continue
    fi

    current_address=$(echo "$current_line" | awk '{print $2}')
    current_state=$(echo "$current_line" | awk '{print $4}')

    if [ "$method" == "static" ] && [ "$address" != "$current_address" ]; then
      echo "Interface $iface has mismatched IP. Configured: $address, Current: $current_address"
    fi

    if [ "$method" == "manual" ] && [ "$current_state" != "UP" ]; then
      echo "Interface $iface is not UP as expected."
    fi

  done <<< "$config"
}

# Run the syntax check for interfaces
echo "Checking for syntax errors in $INTERFACES_CONFIG_FILE..."
parse_interfaces_config | grep "Syntax error\|Invalid" || echo "No syntax errors found."

# Compare interface configurations
compare_configs

# Check the DNS configuration
echo
echo "Checking DNS configuration in $RESOLV_CONF_FILE..."
parse_resolv_conf
