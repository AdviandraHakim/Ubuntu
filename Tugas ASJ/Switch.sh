#!/bin/bash

# Variabel Konfigurasi
SWITCH_IP="192.168.1.1"       # IP Cisco Switch
USER_SWITCH="admin"            # Username Cisco Switch
PASSWORD_SWITCH="password"     # Password Cisco Switch
VLAN_ID=10                     # VLAN ID yang ingin dibuat
VLAN_NAME="VLAN10"             # Nama VLAN
PORT_RANGE="Ethernet0/1"  # Rentang port untuk VLAN
TRUNK_PORT="Ethernet0/0" # Port trunk untuk menghubungkan ke router/switch lain
IP_ROUTER="192.168.1.1"        # IP Router untuk routing antar VLAN
DESCRIPTION="VLAN 10 Network"  # Deskripsi port

# 1. Konfigurasi VLAN
echo "Mengonfigurasi VLAN di Cisco Switch..."
sshpass -p "$PASSWORD_SWITCH" ssh -o StrictHostKeyChecking=no $USER_SWITCH@$SWITCH_IP <<EOF
enable
configure terminal
vlan $VLAN_ID
name $VLAN_NAME
exit
EOF

# 2. Konfigurasi port access untuk VLAN
echo "Mengonfigurasi port access untuk VLAN $VLAN_NAME..."
sshpass -p "$PASSWORD_SWITCH" ssh -o StrictHostKeyChecking=no $USER_SWITCH@$SWITCH_IP <<EOF
enable
configure terminal
interface range $PORT_RANGE
switchport mode access
switchport access vlan $VLAN_ID
description "$DESCRIPTION"
exit
EOF

# 3. Konfigurasi port trunk untuk komunikasi antar switch
echo "Mengonfigurasi port trunk untuk komunikasi antar switch..."
sshpass -p "$PASSWORD_SWITCH" ssh -o StrictHostKeyChecking=no $USER_SWITCH@$SWITCH_IP <<EOF
enable
configure terminal
interface $TRUNK_PORT
switchport mode trunk
switchport trunk allowed vlan add $VLAN_ID
exit
EOF

# 4. Menyimpan konfigurasi
echo "Menyimpan konfigurasi ke memori..."
sshpass -p "$PASSWORD_SWITCH" ssh -o StrictHostKeyChecking=no $USER_SWITCH@$SWITCH_IP <<EOF
enable
write memory
EOF

echo "Konfigurasi Cisco Switch selesai."
