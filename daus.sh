#!/bin/sh

apt install expect -y
apt install telnet 

MIKROTIK_USER="admin"
MIKROTIK_PASS="123"
MIKROTIK_IP="192.168.195.134"
MIKROTIK_PORT="30015"

expect << EOF
spawn telnet $MIKROTIK_IP $MIKROTIK_PORT
expect "login:"
send "$MIKROTIK_USER\r"
expect "Password:"
send "$MIKROTIK_PASS\r"
expect ">"

# Menambahkan DHCP Client di ether1
send "/interface dhcp-client add interface=ether1 disabled=no\r"
expect ">"

# Menambahkan IP address di ether2
send "/ip address add address=192.168.200.1/24 interface=ether2\r"
expect ">"

# Membuat IP pool
send "/ip pool add name=dhcp_pool ranges=192.168.200.10-192.168.200.100\r"
expect ">"

# Menambahkan DHCP Server
send "/ip dhcp-server add name=dhcp1 interface=ether2 address-pool=dhcp_pool disabled=no\r"
expect ">"

# Menambahkan konfigurasi network DHCP Server
send "/ip dhcp-server network add address=192.168.200.0/24 gateway=192.168.200.1\r"
expect ">"

# Mengaktifkan DHCP Server
send "/ip dhcp-server enable dhcp1\r"
expect ">"

# Menambahkan static route ke Ubuntu Server
send "/ip route add dst-address=192.168.22.0/24 gateway=192.168.200.10\r"
expect ">"

# Menambahkan aturan firewall NAT untuk internet sharing
send "/ip firewall nat add chain=srcnat out-interface=ether1 action=masquerade\r"
expect ">"

# Keluar dari MikroTik
send "exit\r"
expect eof
EOF
