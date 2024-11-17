#!/bin/bash

# Repo Kartolo
cat <<EOF | sudo tee /etc/apt/sources.list
deb http://kartolo.sby.datautama.net.id/ubuntu/ focal main restricted universe multiverse
deb http://kartolo.sby.datautama.net.id/ubuntu/ focal-updates main restricted universe multiverse
deb http://kartolo.sby.datautama.net.id/ubuntu/ focal-security main restricted universe multiverse
deb http://kartolo.sby.datautama.net.id/ubuntu/ focal-backports main restricted universe multiverse
deb http://kartolo.sby.datautama.net.id/ubuntu/ focal-proposed main restricted universe multiverse
EOF

sudo apt update

# Netplan Lamine Yamal
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
      - 192.168.20.1/24
EOT
netplan apply

sudo apt install isc-dhcp-server

# Dhcp
sudo bash -c 'cat > /etc/dhcp/dhcpd.conf' << EOF
# A slightly different configuration for an internal subnet.
subnet 192.168.20.0 netmask 255.255.255.0 {
  range 192.168.20.2 192.168.20.254;
  option domain-name-servers 8.8.8.8;
#  option domain-name "internal.example.org";
  option subnet-mask 255.255.255.0;
  option routers 192.168.20.1;
  option broadcast-address 192.168.20.255;
  default-lease-time 600;
  max-lease-time 7200;
}
EOF

# Isc-dhcp-server
echo 'INTERFACESv4="eth1.10"' > /etc/default/isc-dhcp-server
systemctl restart isc-dhcp-server

# ip forward
sudo /etc/sysctl.conf
net.ipv4.ip_forward=1

# Masquerade 
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
sudo apt install iptables-persistent

#install sshpass
sudo apt install sshpass -y

# ============================================================
# Cisco
# ============================================================

# Variabel Konfigurasi
SWITCH_IP="192.168.20.35"       # IP Cisco Switch (diubah sesuai permintaan)
USER_SWITCH="root"             # Username SSH untuk Cisco Switch
PASSWORD_SWITCH="root"         # Password untuk Cisco Switch
VLAN_ID=10
VLAN_NAME="Epul"
INTERFACE="e0/0"               # Port yang digunakan di Cisco Switch

# Warna untuk tampilan
RED='\033[31m'
GREEN='\033[32m'
CYAN='\033[36m'
RESET='\033[0m'

# Fungsi untuk menampilkan pesan sukses atau gagal
print_status() {
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}✔ Konfigurasi Cisco Switch berhasil!${RESET}"
  else
    echo -e "${RED}✘ Gagal mengonfigurasi Cisco Switch!${RESET}"
    exit 1
  fi
}

echo -e "${CYAN}Memulai konfigurasi Cisco Switch...${RESET}"

# Login ke Cisco Switch dan lakukan konfigurasi VLAN
echo -e "${CYAN}Membuat VLAN $VLAN_ID ($VLAN_NAME) di Cisco Switch...${RESET}"
sshpass -p "$PASSWORD_SWITCH" ssh -o StrictHostKeyChecking=no $USER_SWITCH@$SWITCH_IP <<EOF
enable
configure terminal
vlan $VLAN_ID
name $VLAN_NAME
exit
interface $INTERFACE
switchport mode access
switchport access vlan $VLAN_ID
exit
end
write memory
EOF

# Cek status konfigurasi
print_status