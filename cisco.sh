#!/bin/bash

echo -e "${GREEN}${PROGRES[10]}${NC}"

CISCO_IP="192.168.195.134"
CISCO_PORT="30013"

# Menambahkan log untuk setiap langkah
log_step() {
    echo "[INFO] $1"
}

log_step "Memulai koneksi ke perangkat Cisco."
expect <<EOF
spawn telnet $CISCO_IP $CISCO_PORT
set timeout 10

log_step "Masuk ke mode enable."
expect ">" { send "enable\r" }

log_step "Masuk ke konfigurasi terminal."
expect "#" { send "configure terminal\r" }

log_step "Mengonfigurasi interface Ethernet0/1 sebagai access mode."
expect "(config)#" { send "interface Ethernet0/1\r" }
expect "(config-if)#" { send "switchport mode access\r" }
expect "(config-if)#" { send "switchport access vlan 10\r" }
expect "(config-if)#" { send "no shutdown\r" }
expect "(config-if)#" { send "exit\r" }

log_step "Mengonfigurasi interface Ethernet0/0 sebagai trunk mode."
expect "(config)#" { send "interface Ethernet0/0\r" }
expect "(config-if)#" { send "switchport trunk encapsulation dot1q\r" }
expect "(config-if)#" { send "switchport mode trunk\r" }
expect "(config-if)#" { send "no shutdown\r" }
expect "(config-if)#" { send "exit\r" }

log_step "Menyelesaikan konfigurasi dan keluar."
expect "(config)#" { send "exit\r" }
expect "#" { send "exit\r" }
expect eof
EOF

log_step "Konfigurasi selesai."