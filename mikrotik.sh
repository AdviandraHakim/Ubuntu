#!/bin/bash

# Konfigurasi
ROUTER_IP="192.168.195.134"
TELNET_PORT=30014
USERNAME="admin"
OLD_PASSWORD=""  # Ganti dengan password lama jika ada
NEW_PASSWORD="123"

# Perintah konfigurasi yang akan dijalankan di Mikrotik
CONFIG_COMMANDS=(
    "/ip address add address=192.168.20.1/24 interface=ether1"
    "/ip dns set servers=8.8.8.8"
    "/ip firewall nat add chain=srcnat action=masquerade out-interface=ether1"
    "/interface bridge add name=bridge1"
    "/interface bridge port add bridge=bridge1 interface=ether2"
    "/interface bridge port add bridge=bridge1 interface=ether3"
)

# Fungsi untuk menjalankan Telnet dan mengirim perintah
function mikrotik_config() {
    /usr/bin/expect <<EOF
set timeout 10

# Buka koneksi Telnet
spawn telnet $ROUTER_IP $TELNET_PORT

# Login
expect "Login:"
send "$USERNAME\r"

# Password lama (kosong jika tidak ada)
expect "Password:"
send "$OLD_PASSWORD\r"

# Ganti password jika diminta
expect {
    "New Password:" {
        send "$NEW_PASSWORD\r"
        expect "Retype New Password:"
        send "$NEW_PASSWORD\r"
    }
    ">" { }
}

# Masuk ke mode konfigurasi
send "\r"

# Jalankan perintah konfigurasi
foreach cmd in {${CONFIG_COMMANDS[@]}} {
    send "$cmd\r"
    expect ">"
}

# Selesai dan logout
send "quit\r"
expect eof
EOF
}

# Eksekusi fungsi konfigurasi
mikrotik_config

echo "Konfigurasi selesai!"