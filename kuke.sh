# Variabel Mikrotik
MIKROTIK_IP="192.168.195.134"  # IP Mikrotik (dalam topologi: 192.168.A.X)
MIKROTIK_PORT="30014"             # Port Telnet default (23)
MIKROTIK_USER=""          # Username Mikrotik (default: admin)
MIKROTIK_PASSWORD=""   # Ganti dengan password Mikrotik Anda

# Perintah konfigurasi Mikrotik
echo -e "\033[1;32mMengonfigurasi Mikrotik melalui Telnet...\033[0m"

expect <<EOF
spawn telnet $MIKROTIK_IP $MIKROTIK_PORT
expect "Login:"
send "$MIKROTIK_USER\r"
expect "Password:"
send "$MIKROTIK_PASSWORD\r"

# Konfigurasi Interface
expect ">"
send "/interface ethernet set [find default-name=ether1] name=eth1\r"
expect ">"
send "/interface ethernet set [find default-name=ether2] name=eth2\r"

# Konfigurasi IP Address untuk eth1 dan eth2
expect ">"
send "/ip address add address=192.168.22.1/24 interface=eth1 comment=\"Ke VLAN\"\r"
expect ">"
send "/ip address add address=192.168.200.1/24 interface=eth2 comment=\"Jaringan Lokal\"\r"

# Konfigurasi DHCP Client pada eth1 (untuk mendapatkan akses internet)
expect ">"
send "/ip dhcp-client add interface=eth1 disabled=no comment=\"DHCP ke ISP\"\r"

# Konfigurasi NAT (Masquerade)
expect ">"
send "/ip firewall nat add chain=srcnat out-interface=eth1 action=masquerade comment=\"NAT Masquerade\"\r"

# Konfigurasi Routing (Default Gateway untuk eth1)
expect ">"
send "/ip route add dst-address=192.168.22.0/24 gateway=192.168.200.10\r"

# Konfigurasi DHCP Server untuk jaringan lokal (192.168.200.0/24)
expect ">"
send "/ip pool add name=dhcp_pool ranges=192.168.200.2-192.168.200.254\r"
expect ">"
send "/ip dhcp-server add name=dhcp_local interface=eth2 address-pool=dhcp_pool disabled=no\r"
expect ">"
send "/ip dhcp-server network add address=192.168.200.0/24 gateway=192.168.200.1 dns-server=8.8.8.8 comment=\"DHCP untuk Local\"\r"

# Keluar
expect ">"
send "quit\r"
EOF

echo -e "\033[1;32mKonfigurasi Mikrotik selesai melalui Telnet!\033[0m"
