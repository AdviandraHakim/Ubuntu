#!/bin/sh

apt install expect -y
apt install telnet 

MIKROTIK_USER="admin"
MIKROTIK_PASS="123"
MIKROTIK_IP="192.168.195.134"
MIKROTIK_PORT="30014"

expect << EOF
spawn telnet $MIKROTIK_IP $MIKROTIK_PORT
expect "login:"
send "$MIKROTIK_USER\r"
expect "Password:"
send "$MIKROTIK_PASS\r"
expect ">"

# konfigurasi
send "/ip dhcp-server network add address=192.168.200.0/24 gateway=192.168.200.1 dns-server=8.8.8.8
expect  ">"

# dhcp server
send "/ip pool add name=pooll range=192.168.200.1-192.168.200.254
expect  ">"

# dhcp server nama
send  "/ip dhcp-server add name=dhcp1 interface=ether2 address-pool=pooll disable=no
expect  ">"

# menambahkan ip
send  "/ip add add address=192.168.22.2/24 interfabe=ether1 
expect  ">"

# routing
send  "/ip route add gateway=192.168.22.1
expect  ">"

# masquerade
send  "/ip firewall nat add chain=srcnat out-interface=ether1 action=masquerade
expect  ">"

# 1
send  "/ip dhcp-server enable 0
expect  ">"

# 2
send  "/ip dhcp-server net pr
expect  ">"

# 3
send  "/ip dhcp-server set 0 address-pool=pooll
expect  ">"

# 4
send  "/int pr
expect  ">"

# masquerade
send  "/int en ether2
expect  ">"

# masquerade
send  "/ip dhcp-server disable 0
expect  ">"
send  "/ip dhcp-server enable 0
expect  ">"

# Keluar dari MikroTik
send "exit\r"
expect eof
EOF
