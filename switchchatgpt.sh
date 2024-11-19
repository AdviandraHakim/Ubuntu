#!/bin/bash

echo "=== Skrip Otomasi Konfigurasi Switch Cisco ==="

# Variabel untuk koneksi dan konfigurasi
SWITCH_IP="192.168.22.X"            # IP switch Cisco
SWITCH_USER="cisco"                 # Username SSH switch
SWITCH_PASSWORD="password_switch"   # Password SSH switch
VLAN_ID=10                          # VLAN ID yang akan dikonfigurasi
VLAN_NAME="VLAN10"                  # Nama VLAN
VLAN_IP="192.168.22.254"            # IP VLAN untuk pengelolaan
SUBNET_MASK="255.255.255.0"         # Subnet mask untuk VLAN
ACCESS_PORT="e0/1"                  # Port akses yang terhubung ke perangkat VLAN 10
TRUNK_PORT="e0/0"                   # Port trunk yang terhubung ke perangkat lain

# Konfigurasi di switch
echo "=== Memulai Konfigurasi ==="
sshpass -p "$SWITCH_PASSWORD" ssh -o StrictHostKeyChecking=no $SWITCH_USER@$SWITCH_IP << EOF
enable
configure terminal

# Buat VLAN
vlan $VLAN_ID
name $VLAN_NAME
exit

# Konfigurasi interface VLAN untuk pengelolaan
interface vlan $VLAN_ID
ip address $VLAN_IP $SUBNET_MASK
no shutdown
exit

# Konfigurasi port akses untuk VLAN
interface $ACCESS_PORT
switchport mode access
switchport access vlan $VLAN_ID
exit

# Konfigurasi port trunk untuk VLAN
interface $TRUNK_PORT
switchport mode trunk
switchport trunk allowed vlan $VLAN_ID
exit

# Simpan konfigurasi
write memory
EOF

echo "=== Konfigurasi Switch Cisco Selesai ==="
