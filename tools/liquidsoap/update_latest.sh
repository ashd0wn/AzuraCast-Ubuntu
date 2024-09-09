#!/usr/bin/env bash

# Stop anything
supervisorctl stop all || :

# Get the latest release tag name for Icecast
# Construct the release URL for Icecast
release_url="https://github.com/savonet/liquidsoap/releases/download/v2.2.3/liquidsoap_2.2.3-ubuntu-jammy-1_amd64.deb"

# Download the latest Liquidsoap .deb package
curl -LO "$release_url"

# Install Liquidsoap and its dependencies
dpkg -i liquidsoap_2.2.3-ubuntu-jammy-1_amd64.deb

# Update package list
apt_get_with_lock update

# Upgrade Liquidsoap and its dependencies
apt_get_with_lock upgrade -y liquidsoap

# Clean up
rm liquidsoap_2.2.3-ubuntu-jammy-1_amd64.deb

# Start anything
supervisorctl start all || :

