#!/bin/bash

# Extract interface details from 'ip a'
INTERFACES=$(ip a | grep -oP '^\d+: \K\w+')

# Start generating the network configuration
CONFIG=""

for INTERFACE in $INTERFACES; do
    # Get interface details
    LINK_INFO=$(ip a show dev $INTERFACE | grep -oP '^\s+link/ether \K\S+')
    IPV4_INFO=$(ip a show dev $INTERFACE | grep -oP '^\s+inet \K\S+')
    IPV6_INFO=$(ip a show dev $INTERFACE | grep -oP '^\s+inet6 \K\S+')

    # Check if this is the loopback interface
    if [[ $INTERFACE == "lo" ]]; then
        CONFIG+="auto lo\niface lo inet loopback\n"
    else
        if [[ -n $IPV4_INFO ]]; then
            CONFIG+="auto $INTERFACE\niface $INTERFACE inet dhcp\n"
        else
            CONFIG+="auto $INTERFACE\niface $INTERFACE inet manual\n"
        fi

        # Check for master interface (bridge)
        MASTER=$(ip link show $INTERFACE | grep -oP 'master \K\w+')
        if [[ -n $MASTER ]]; then
            CONFIG+="\tbridge_ports $INTERFACE\n"
            CONFIG+="\tbridge_fd 0\n"
            CONFIG+="\tbridge_stp off\n"
        fi
    fi
done

# Print the generated configuration
echo -e "$CONFIG"
