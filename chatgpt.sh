#!/bin/bash

# ============================================================
# Skrip Otomasi Konfigurasi VLAN 10 di Ubuntu, Cisco Switch, & MikroTik
# ============================================================

# Fungsi untuk mencetak teks di tengah layar
print_center() {
  term_width=$(tput cols) # Lebar terminal
  text="$1"               # Teks yang akan dicetak
  text_length=${#text}    # Panjang teks
  padding=$(( (term_width - text_length) / 2 ))
  printf "%*s%s\n" $padding "" "$text"
}

# Menampilkan teks dengan pemformatan
clear
print_center ""
print_center "██   ██  █████  ██   ██ ██ ███    ███ ███████ ███████ "
print_center "██   ██ ██   ██ ██  ██  ██ ████  ████    ███     ███ "
print_center "███████ ███████ █████   ██ ██ ████ ██   ███     ███ "
print_center "██   ██ ██   ██ ██  ██  ██ ██  ██  ██  ███     ███ "
print_center "██   ██ ██   ██ ██   ██ ██ ██      ██ ███████ ███████ "
print_center ""
print_center ""
print_center ""
print_center "+-+-+-+ +-+-+-+-+ +-+ +-+-+-+-+-+-+-+"
print_center "|S|E|R|L|O|K| |T||A||K| |P|A|R|A|N|I|"
print_center "+-+-+-+ +-+-+-+-+ +-+ +-+-+-+-+-+-+-+"
print_center ""
print_center ""
print_center ""

# Jeda waktu 5 detik
sleep 5


# ===== Konfigurasi Ubuntu Server =====
echo -e "\033[0;32m=== Memulai konfigurasi Ubuntu Server ===\033[0m"

# 1. Mengganti repository menjadi repository lokal Kartolo
echo -e "\033[0;32mMengganti repository ke Kartolo\033[0m"
cat <<EOF > /etc/apt/sources.list
deb http://kartolo.sby.datautama.net.id/ubuntu/ focal main restricted universe multiverse
deb http://kartolo.sby.datautama.net.id/ubuntu/ focal-updates main restricted universe multiverse
deb http://kartolo.sby.datautama.net.id/ubuntu/ focal-security main restricted universe multiverse
deb http://kartolo.sby.datautama.net.id/ubuntu/ focal-backports main restricted universe multiverse
deb http://kartolo.sby.datautama.net.id/ubuntu/ focal-proposed main restricted universe
EOF

apt update &> /dev/null
echo -e "\033[0;32mBerhasil mengganti repository dan mengupdate sistem\033[0m"

# 2. Install DHCP Server dan iptables-persistent
echo -e "\033[0;32mMenginstall DHCP Server dan iptables-persistent\033[0m"
apt install -y isc-dhcp-server iptables iptables-persistent &> /dev/null
echo -e "\033[0;32mBerhasil menginstall DHCP Server dan iptables-persistent\033[0m"

# 3. Konfigurasi Netplan untuk VLAN 10
echo -e "\033[0;32mMengonfigurasi jaringan dengan VLAN 10\033[0m"
cat <<EOT > /etc/netplan/01-netcfg.yaml
network:
  version: 2
  ethernets:
    eth0:
      dhcp4: yes   # Terhubung ke Internet
    eth1:
      dhcp4: no    # Terhubung ke Mikrotik / Switch
  vlans:
    eth1.10:
      id: 10
      link: eth1
      addresses:
        - 192.168.22.1/24
EOT

netplan apply
echo -e "\033[0;32mBerhasil menerapkan konfigurasi Netplan\033[0m"

# 4. Konfigurasi DHCP Server
echo -e "\033[0;32mMengonfigurasi DHCP Server\033[0m"
cat <<EOF > /etc/dhcp/dhcpd.conf
subnet 192.168.22.0 netmask 255.255.255.0 {
    range 192.168.22.100 192.168.22.200;
    option domain-name-servers 8.8.8.8;
    option subnet-mask 255.255.255.0;
    option routers 192.168.22.1;
    option broadcast-address 192.168.22.255;
    default-lease-time 600;
    max-lease-time 7200;
}
EOF

echo 'INTERFACESv4="eth1.10"' > /etc/default/isc-dhcp-server
systemctl restart isc-dhcp-server
echo -e "\033[0;32mBerhasil mengkonfigurasi dan me-restart DHCP Server\033[0m"

# 5. Aktifkan IP Forwarding
echo -e "\033[0;32mMengaktifkan IP Forwarding\033[0m"
sysctl -w net.ipv4.ip_forward=1 &> /dev/null
sed -i '/net.ipv4.ip_forward/d' /etc/sysctl.conf
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf

# 6. Konfigurasi NAT dengan iptables
echo -e "\033[0;32mMengonfigurasi iptables untuk NAT\033[0m"
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
iptables-save > /etc/iptables/rules.v4
echo -e "\033[0;32mBerhasil menyimpan aturan iptables\033[0m"

# ===== Konfigurasi Cisco Switch =====
echo -e "\033[0;32m=== Konfigurasi Switch Cisco ===\033[0m"
SWITCH_IP="192.168.1.100"
SWITCH_USER="admin"
SWITCH_PASS="password"
ACCESS_INTERFACE="FastEthernet0/1"
TRUNK_INTERFACE="FastEthernet0/0"
VLAN_ID=10

/usr/bin/expect <<EOF
spawn ssh $SWITCH_USER@$SWITCH_IP
expect "Password:" { send "$SWITCH_PASS\r" }
expect ">" { send "enable\r" }
expect "#" { send "configure terminal\r" }
expect "(config)#" { send "vlan $VLAN_ID\r" }
expect "(config-vlan)#" { send "exit\r" }
expect "(config)#" { send "interface $ACCESS_INTERFACE\r" }
expect "(config-if)#" { send "switchport mode access\r" }
expect "(config-if)#" { send "switchport access vlan $VLAN_ID\r" }
expect "(config-if)#" { send "exit\r" }
expect "(config)#" { send "interface $TRUNK_INTERFACE\r" }
expect "(config-if)#" { send "switchport mode trunk\r" }
expect "(config-if)#" { send "switchport trunk allowed vlan $VLAN_ID\r" }
expect "(config-if)#" { send "exit\r" }
expect "(config)#" { send "end\r" }
expect "#" { send "write memory\r" }
expect "#" { send "exit\r" }
EOF

# ===== Konfigurasi MikroTik =====
echo -e "\033[0;32m=== Konfigurasi MikroTik ===\033[0m"
read -p "Masukkan IP MikroTik: " MIKROTIK_IP
read -p "Masukkan username MikroTik: " MIKROTIK_USER
read -s -p "Masukkan password MikroTik: " MIKROTIK_PASS

sshpass -p "$MIKROTIK_PASS" ssh -o StrictHostKeyChecking=no $MIKROTIK_USER@$MIKROTIK_IP << EOF
/interface vlan add name=vlan10 vlan-id=10 interface=ether1
/ip address add address=192.168.22.254/24 interface=vlan10
EOF

echo -e "\033[0;32m=== Konfigurasi selesai ===\033[0m"