#!/bin/bash

# ============================================================
# Skrip Otomasi Konfigurasi VLAN 10 di Ubuntu, Cisco Switch, & MikroTik
# ============================================================

# Membersihkan layar
clear

# Menampilkan teks ASCII art secara manual
echo "\n██   ██  █████  ██   ██ ██ ███    ███ ███████ ███████ "
echo "██   ██ ██   ██ ██  ██  ██ ████  ████    ███     ███  "
echo "███████ ███████ █████   ██ ██ ████ ██   ███     ███   "
echo "██   ██ ██   ██ ██  ██  ██ ██  ██  ██  ███     ███    "
echo "██   ██ ██   ██ ██   ██ ██ ██      ██ ███████ ███████ "
echo "\n"
echo "+-+-+-+ +-+-+-+-+ +-+ +-+-+-+-+-+-+-+"
echo "|S|E|R|L|O|K| |T||A||K| |P|A|R|A|N|I|"
echo "+-+-+-+ +-+-+-+-+ +-+ +-+-+-+-+-+-+-+"
echo "\n"

# Variabel untuk progres
PROGRES=("Menambahkan Repository Kymm" "Melakukan update paket" "Mengonfigurasi netplan" "Menginstal DHCP server" \
         "Mengonfigurasi DHCP server" "Mengaktifkan IP Forwarding" "Mengonfigurasi Masquerade" \
         "Menginstal iptables-persistent" "Menyimpan konfigurasi iptables"  \
         "Menginstal Expect" "Konfigurasi Cisco" "Konfigurasi Mikrotik")

# Warna untuk output
GREEN='\033[1;32m'
RED='\033[1;31m'
NC='\033[0m'

# Fungsi untuk pesan sukses dan gagal
success_message() { echo -e "${GREEN}$1 berhasil!${NC}"; }
error_message() { echo -e "${RED}$1 gagal!${NC}"; exit 1; }

# Otomasi Dimulai
echo "Otomasi Dimulai"

# Menambahkan Repository Ban
echo -e "${GREEN}${PROGRES[0]}${NC}"
REPO="http://kartolo.sby.datautama.net.id/ubuntu/"
if ! grep -q "$REPO" /etc/apt/sources.list; then
    cat <<EOF | sudo tee /etc/apt/sources.list > /dev/null
deb ${REPO} focal main restricted universe multiverse
deb ${REPO} focal-updates main restricted universe multiverse
deb ${REPO} focal-security main restricted universe multiverse
deb ${REPO} focal-backports main restricted universe multiverse
deb ${REPO} focal-proposed main restricted universe multiverse
EOF
fi

# Update Paket
echo -e "${GREEN}${PROGRES[1]}${NC}"
sudo apt update -y > /dev/null 2>&1 || error_message "${PROGRES[1]}"

# Konfigurasi Netplan
echo -e "${GREEN}${PROGRES[2]}${NC}"
cat <<EOT | sudo tee /etc/netplan/01-netcfg.yaml > /dev/null
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
sudo netplan apply > /dev/null 2>&1 || error_message "${PROGRES[2]}"

# Instalasi ISC DHCP Server
echo -e "${GREEN}${PROGRES[3]}${NC}"
# Perbaikan paket yang rusak dan instalasi ulang jika perlu
sudo apt --fix-broken install -y > /dev/null 2>&1 || error_message "Perbaikan paket gagal"
if ! dpkg -l | grep -qw isc-dhcp-server; then
    sudo apt install -y isc-dhcp-server > /dev/null 2>&1 || error_message "${PROGRES[3]}"
else
    success_message "${PROGRES[3]} sudah terinstal"
fi

# Konfigurasi DHCP Server
echo -e "${GREEN}${PROGRES[4]}${NC}"
sudo bash -c 'cat > /etc/dhcp/dhcpd.conf' << EOF
subnet 192.168.22.0 netmask 255.255.255.0 {
  range 192.168.22.2 192.168.22.254;
  option domain-name-servers 8.8.8.8;
  option subnet-mask 255.255.255.0;
  option routers 192.168.22.1;
  option broadcast-address 192.168.22.255;
  default-lease-time 600;
  max-lease-time 7220;

  host Ban {
    hardware ethernet 00:50:79:66:68:0f;
    fixed-address 192.168.22.10;
  }
}
EOF
echo 'INTERFACESv4="eth1.10"' | sudo tee /etc/default/isc-dhcp-server > /dev/null
sudo systemctl restart isc-dhcp-server > /dev/null 2>&1 || error_message "${PROGRES[4]}"

# Aktifkan IP Forwarding
echo -e "${GREEN}${PROGRES[5]}${NC}"
sudo sed -i '/^#net.ipv4.ip_forward=1/s/^#//' /etc/sysctl.conf
sudo sysctl -p > /dev/null 2>&1 || error_message "${PROGRES[5]}"

# Konfigurasi Masquerade dengan iptables
echo -e "${GREEN}${PROGRES[6]}${NC}"
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE > /dev/null 2>&1 || error_message "${PROGRES[6]}"

# Instalasi iptables-persistent dengan otomatisasi
echo -e "${GREEN}${PROGRES[7]}${NC}"
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | sudo debconf-set-selections > /dev/null 2>&1
echo iptables-persistent iptables-persistent/autosave_v6 boolean false | sudo debconf-set-selections > /dev/null 2>&1
sudo apt install -y iptables-persistent > /dev/null 2>&1 || error_message "${PROGRES[7]}"

# Menyimpan Konfigurasi iptables
echo -e "${GREEN}${PROGRES[8]}${NC}"
sudo sh -c "iptables-save > /etc/iptables/rules.v4" > /dev/null 2>&1 || error_message "${PROGRES[8]}"
sudo sh -c "ip6tables-save > /etc/iptables/rules.v6" > /dev/null 2>&1 || error_message "${PROGRES[8]}"

# Instalasi Expect
echo -e "${GREEN}${PROGRES[9]}${NC}"
if ! command -v expect > /dev/null; then
    sudo apt install -y expect > /dev/null 2>&1 || error_message "${PROGRES[9]}"
else
    success_message "${PROGRES[9]} sudah terinstal"
fi

# Menambahkan IP Route
echo "Menambahkan IP Route"
sudo ip route add 192.168.200.0/24 via 192.168.22.2 || success_message "IP Route sudah ada"

# Selesai
echo -e "${GREEN}Skrip selesai dengan sukses!${NC}"
