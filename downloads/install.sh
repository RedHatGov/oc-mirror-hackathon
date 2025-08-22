#!/bin/bash

#==============================================================================
# OpenShift Tools Installation Script (for disconnected systems)
#==============================================================================
# This script installs OpenShift tools from the downloads directory
# Usage: ./install.sh
#==============================================================================

set -e

echo "=== Installing OpenShift Tools ==="

# Check if running as root or with sudo
if [[ $EUID -eq 0 ]]; then
    CP_CMD="cp"
    CHMOD_CMD="chmod"
else
    CP_CMD="sudo cp"
    CHMOD_CMD="sudo chmod"
fi

# Install binaries to system PATH
echo "Installing oc-mirror..."
$CP_CMD oc-mirror /usr/local/bin/

echo "Installing oc..."  
$CP_CMD oc /usr/local/bin/

echo "Installing openshift-install..."
$CP_CMD openshift-install /usr/local/bin/

echo "Installing butane..."
$CP_CMD butane /usr/local/bin/butane

# Set permissions
echo "Setting permissions..."
$CHMOD_CMD +x /usr/local/bin/oc-mirror
$CHMOD_CMD +x /usr/local/bin/oc  
$CHMOD_CMD +x /usr/local/bin/openshift-install
$CHMOD_CMD +x /usr/local/bin/butane

echo ""
echo "=== Installation Complete ==="
echo "Installed tools:"
echo "  • oc-mirror"
echo "  • oc" 
echo "  • openshift-install"
echo "  • butane"
echo ""
echo "Mirror registry available in: mirror-registry/"
echo ""
echo "Test with:"
echo "  oc version"
echo "  openshift-install version"
echo "  oc-mirror --help"
echo ""
echo "Setup oc bash completion"
echo "  oc completion bash > ~/.oc_bash_completion"
echo "  echo 'source ~/.oc_bash_completion' >> ~/.bashrc" 