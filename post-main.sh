#!/bin/bash
echo "RESTORING NORMAL..."

# REVERSE ALL 6 COMMANDS:
sudo macchanger -p wlan0                  # 1. Original MAC
sudo iptables -P INPUT ACCEPT            # 2. Allow incoming
sudo iptables -F                         # 3. Clear all rules
sudo sysctl -w net.ipv6.conf.all.disable_ipv6=0  # 4. Enable IPv6
sudo systemctl start avahi-daemon        # 5. Start network discovery
sudo systemctl restart NetworkManager    # 6. Restore network

echo "NORMAL - All traces removed"
