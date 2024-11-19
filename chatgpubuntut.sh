#!/bin/bash

# ============================================================
# Skrip Otomasi Konfigurasi VLAN 10 di Ubuntu, Cisco Switch, & MikroTik
# ============================================================

#!/bin/bash

# Membersihkan layar
clear

# Menampilkan teks ASCII art secara manual
echo "██   ██  █████  ██   ██ ██ ███    ███ ███████ ███████ "
echo "██   ██ ██   ██ ██  ██  ██ ████  ████    ███     ███  "
echo "███████ ███████ █████   ██ ██ ████ ██   ███     ███   "
echo "██   ██ ██   ██ ██  ██  ██ ██  ██  ██  ███     ███    "
echo "██   ██ ██   ██ ██   ██ ██ ██      ██ ███████ ███████ "
echo ""

# Menampilkan teks tambahan
echo "+-+-+-+ +-+-+-+-+ +-+ +-+-+-+-+-+-+-+"
echo "|S|E|R|L|O|K| |T||A||K| |P|A|R|A|N|I|"
echo "+-+-+-+ +-+-+-+-+ +-+ +-+-+-+-+-+-+-+"
echo ""


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
# Netplan 
cat <<EOT > /etc/netplan/01-netcfg.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      dhcp4: yes
    eth1:
      dhcp4: no
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
# A slightly different configuration for an internal subnet.
subnet 192.168.20.0 netmask 255.255.255.0 {
  range 192.168.20.2 192.168.22.254;
  option domain-name-servers 8.8.8.8;
#  option domain-name "internal.example.org";
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

