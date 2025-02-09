#!/bin/bash

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

# Menambahkan Repository Kymm
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
    enp0s3:
      dhcp4: no
      addresses:
        - 192.168.22.2/24
      gateway4: 192.168.22.1
      nameservers:
        addresses:
          - 8.8.8.8
EOT
sudo netplan apply > /dev/null 2>&1 || error_message "${PROGRES[2]}"

# Instalasi ISC DHCP Server
echo -e "${GREEN}${PROGRES[3]}${NC}"
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
  option routers 192.168.22.1;
  option broadcast-address 192.168.22.255;
  default-lease-time 600;
  max-lease-time 7200;

  host Kymm {
    hardware ethernet 00:50:79:66:68:0f;
    fixed-address 192.168.22.10;
  }
}
EOF

echo 'INTERFACESv4="enp0s3"' | sudo tee /etc/default/isc-dhcp-server > /dev/null
sudo systemctl restart isc-dhcp-server > /dev/null 2>&1 || error_message "${PROGRES[4]}"

# Aktifkan IP Forwarding
echo -e "${GREEN}${PROGRES[5]}${NC}"
grep -q "^net.ipv4.ip_forward=1" /etc/sysctl.conf || echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p > /dev/null 2>&1 || error_message "${PROGRES[5]}"

# Konfigurasi Masquerade dengan iptables
echo -e "${GREEN}${PROGRES[6]}${NC}"
sudo iptables -t nat -A POSTROUTING -o enp0s3 -j MASQUERADE > /dev/null 2>&1 || error_message "${PROGRES[6]}"

# Instalasi iptables-persistent dengan otomatisasi
echo -e "${GREEN}${PROGRES[7]}${NC}"
sudo apt install -y iptables-persistent > /dev/null 2>&1 || error_message "${PROGRES[7]}"

# Menyimpan Konfigurasi iptables
echo -e "${GREEN}${PROGRES[8]}${NC}"
sudo netfilter-persistent save > /dev/null 2>&1 || error_message "${PROGRES[8]}"

# Instalasi Expect
echo -e "${GREEN}${PROGRES[9]}${NC}"
if ! command -v expect > /dev/null; then
    sudo apt install -y expect > /dev/null 2>&1 || error_message "${PROGRES[9]}"
else
    success_message "${PROGRES[9]} sudah terinstal"
fi

# Menambahkan IP Route
echo "Menambahkan IP Route"
sudo ip route add 10.10.10.0/24 via 192.168.22.1 > /dev/null 2>&1 || success_message "IP Route sudah ada"

# Selesai
echo -e "${GREEN}Skrip selesai dengan sukses!${NC}"
