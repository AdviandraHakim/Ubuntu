#!/bin/bash

# Variabel Konfigurasi
MIKROTIK_IP="192.168.200.1"      # IP MikroTik
USER_MIKROTIK="admin"            # Username MikroTik
PASSWORD_MIKROTIK="password"     # Password MikroTik (Kosongkan jika tidak ada password)
VLAN_ID=10
VLAN_NAME="vlan10"
VLAN_INTERFACE="ether1"          # Interface fisik yang digunakan untuk VLAN
IP_VLAN="192.168.24.1/24"        # IP Address untuk interface VLAN
IP_LAN="192.168.200.1/24"        # IP Address untuk interface LAN
GATEWAY="192.168.200.1"          # Gateway MikroTik
MIKROTIK_ROUTER_IP="192.168.200.254"  # Rute ke router lainnya jika diperlukan

# 1. Konfigurasi VLAN di MikroTik
echo "Mengonfigurasi VLAN di MikroTik..."

if [ -z "$PASSWORD_MIKROTIK" ]; then
    ssh -o StrictHostKeyChecking=no $USER_MIKROTIK@$MIKROTIK_IP <<EOF
interface vlan add name=$VLAN_NAME vlan-id=$VLAN_ID interface=$VLAN_INTERFACE
ip address add address=$IP_VLAN interface=$VLAN_NAME
EOF
else
    sshpass -p "$PASSWORD_MIKROTIK" ssh -o StrictHostKeyChecking=no $USER_MIKROTIK@$MIKROTIK_IP <<EOF
interface vlan add name=$VLAN_NAME vlan-id=$VLAN_ID interface=$VLAN_INTERFACE
ip address add address=$IP_VLAN interface=$VLAN_NAME
EOF
fi

# 2. Konfigurasi IP Address untuk interface lainnya (contoh: ether2 untuk LAN)
echo "Mengonfigurasi IP Address untuk interface LAN di MikroTik..."
if [ -z "$PASSWORD_MIKROTIK" ]; then
    ssh -o StrictHostKeyChecking=no $USER_MIKROTIK@$MIKROTIK_IP <<EOF
ip address add address=$IP_LAN interface=ether2
EOF
else
    sshpass -p "$PASSWORD_MIKROTIK" ssh -o StrictHostKeyChecking=no $USER_MIKROTIK@$MIKROTIK_IP <<EOF
ip address add address=$IP_LAN interface=ether2
EOF
fi

# 3. Menambahkan Rute untuk koneksi antar subnet atau ke jaringan lain
echo "Menambahkan Rute di MikroTik..."
if [ -z "$PASSWORD_MIKROTIK" ]; then
    ssh -o StrictHostKeyChecking=no $USER_MIKROTIK@$MIKROTIK_IP <<EOF
ip route add dst-address=192.168.24.0/24 gateway=$MIKROTIK_ROUTER_IP
EOF
else
    sshpass -p "$PASSWORD_MIKROTIK" ssh -o StrictHostKeyChecking=no $USER_MIKROTIK@$MIKROTIK_IP <<EOF
ip route add dst-address=192.168.24.0/24 gateway=$MIKROTIK_ROUTER_IP
EOF
fi

# 4. Mengaktifkan IP Forwarding jika diperlukan
echo "Mengaktifkan IP Forwarding di MikroTik..."
if [ -z "$PASSWORD_MIKROTIK" ]; then
    ssh -o StrictHostKeyChecking=no $USER_MIKROTIK@$MIKROTIK_IP <<EOF
/ip settings set ip-forward=yes
EOF
else
    sshpass -p "$PASSWORD_MIKROTIK" ssh -o StrictHostKeyChecking=no $USER_MIKROTIK@$MIKROTIK_IP <<EOF
/ip settings set ip-forward=yes
EOF
fi

# 5. Verifikasi Konfigurasi
echo "Verifikasi Konfigurasi MikroTik..."
if [ -z "$PASSWORD_MIKROTIK" ]; then
    ssh -o StrictHostKeyChecking=no $USER_MIKROTIK@$MIKROTIK_IP <<EOF
/interface print
/ip address print
/ip route print
EOF
else
    sshpass -p "$PASSWORD_MIKROTIK" ssh -o StrictHostKeyChecking=no $USER_MIKROTIK@$MIKROTIK_IP <<EOF
/interface print
/ip address print
/ip route print
EOF
fi

echo "Konfigurasi MikroTik selesai."
