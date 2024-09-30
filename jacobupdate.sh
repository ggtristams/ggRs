#!/bin/bash

# Function to log steps and check for errors
log_and_run() {
    echo "Running: $1"
    eval $1
    if [ $? -ne 0 ]; then
        echo "Error encountered during: $1"
        exit 1
    fi
}

# Run ggrock-linux-configurator
log_and_run "ggrock-linux-configurator"

# Update package list
log_and_run "apt-get update"

# Upgrade packages
log_and_run "apt-get upgrade -y"

# Run ggrock-linux-configurator again
log_and_run "ggrock-linux-configurator"

# Check for updates via Debian Control Panel updates tab
echo "Please check the Debian Control Panel updates tab manually for updates."

# If errors are encountered, run wget command
read -p "Were there any errors in the previous steps? (y/n): " ERRORS
if [ "$ERRORS" == "y" ]; then
    log_and_run "wget -O - https://ggrock.com/install.sh | bash -"
fi

# Reboot the server
read -p "Do you want to reboot the server now? (y/n): " REBOOT
if [ "$REBOOT" == "y" ]; then
    log_and_run "reboot"
else
    echo "Reboot skipped. Please remember to reboot the server later."
fi
