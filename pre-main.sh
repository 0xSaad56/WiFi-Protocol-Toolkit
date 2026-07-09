#!/bin/bash
echo "🕶️ ACTIVATING INVISIBILITY..."

# 6 CRITICAL COMMANDS:
sudo macchanger -r wlan0                  # 1. Random MAC
sudo iptables -P INPUT DROP              # 2. Block all incoming
sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1  # 3. Disable IPv6
sudo systemctl stop avahi-daemon         # 4. Stop network discovery
sudo iptables -A INPUT -i lo -j ACCEPT   # 5. Allow localhost only
sudo iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT  # 6. Allow established

echo "Now INVISIBLE - Ready for attack"
