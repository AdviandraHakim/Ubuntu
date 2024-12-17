# Konfigurasi Cisco
echo -e "${YELLOW}${PROGRES[11]}${NC}"
CISCO_IP="192.168.195.134"
CISCO_PORT="30013"
expect <<EOF > /dev/null 2>&1
spawn telnet $CISCO_IP $CISCO_PORT
set timeout 22

expect ">" { send "enable\r" }
expect "#" { send "configure terminal\r" }
expect "(config)#" { send "interface Ethernet0/1\r" }
expect "(config-if)#" { send "switchport mode access\r" }
expect "(config-if)#" { send "switchport access vlan 10\r" }
expect "(config-if)#" { send "no shutdown\r" }
expect "(config-if)#" { send "exit\r" }
expect "(config)#" { send "interface Ethernet0/0\r" }
expect "(config-if)#" { send "switchport trunk encapsulation dot1q\r" }
expect "(config-if)#" { send "switchport mode trunk\r" }
expect "(config-if)#" { send "no shutdown\r" }
expect "(config-if)#" { send "exit\r" }
expect "(config)#" { send "exit\r" }
expect "#" { send "exit\r" }
expect eof
EOF

# ====== Tambahkan ASCII Art Penutup di sini ======
echo -e "\033[1;36m" # Warna Cyan
echo "==============================================="
echo "             Konfigurasi Selesai!              "
echo "==============================================="
echo -e "\033[0m" # Mengembalikan warna default
