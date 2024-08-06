#!/bin/bash

# Check CPU virtualization support
echo "Checking CPU virtualization support..."
cpu_support=$(egrep -c '(vmx|svm)' /proc/cpuinfo)

if [ "$cpu_support" -gt 0 ]; then
  echo "CPU supports virtualization."
else
  echo "CPU does not support virtualization or it is not enabled in the BIOS/UEFI."
  exit 1
fi

# Check if KVM modules are loaded
echo "Checking if KVM modules are loaded..."
if lsmod | grep -q kvm; then
  echo "KVM modules are already loaded."
else
  echo "KVM modules are not loaded. Loading them now..."
  sudo modprobe kvm
  if grep -q 'vmx' /proc/cpuinfo; then
    sudo modprobe kvm_intel
  elif grep -q 'svm' /proc/cpuinfo; then
    sudo modprobe kvm_amd
  fi

  # Verify if the modules were loaded successfully
  if lsmod | grep -q kvm; then
    echo "KVM modules loaded successfully."
  else
    echo "Failed to load KVM modules. Please check your system settings and try again."
    exit 1
  fi
fi

# Display the last few KVM-related messages from the kernel log
echo "Displaying the last few KVM-related messages from the kernel log..."
dmesg | grep kvm | tail

echo "KVM is set up and ready to use."
