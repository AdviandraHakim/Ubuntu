#!/bin/bash

# Variabel untuk progres
PROGRES=("Menambahkan Repository Kymm" "Melakukan update paket" "Mengonfigurasi netplan" "Mengaktifkan IP Forwarding" "Mengonfigurasi Masquerade" \
         "Menginstal iptables-persistent" "Menyimpan konfigurasi iptables"  "Menginstal Expect" "Mengonfigurasi SSH" "Konfigurasi Cisco" "Konfigurasi Mikrotik")

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
  ethernets:
    enp0s3:
      dhcp4: no
      addresses:
        - 192.168.22.2/24
      gateway4: 192.168.22.1
      nameservers:
        addresses:
          - 8.8.8.8
  version: 2
EOT
sudo netplan apply > /dev/null 2>&1 || error_message "${PROGRES[2]}"

# Aktifkan IP Forwarding
echo -e "${GREEN}${PROGRES[3]}${NC}"
sudo sed -i '/^#net.ipv4.ip_forward=1/s/^#//' /etc/sysctl.conf
sudo sysctl -p > /dev/null 2>&1 || error_message "${PROGRES[3]}"

# Konfigurasi Masquerade dengan iptables
echo -e "${GREEN}${PROGRES[4]}${NC}"
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE > /dev/null 2>&1 || error_message "${PROGRES[4]}"

# Instalasi iptables-persistent
echo -e "${GREEN}${PROGRES[5]}${NC}"
sudo apt install -y iptables-persistent > /dev/null 2>&1 || error_message "${PROGRES[5]}"

# Menyimpan Konfigurasi iptables
echo -e "${GREEN}${PROGRES[6]}${NC}"
sudo iptables-save > /etc/iptables/rules.v4 > /dev/null 2>&1 || error_message "${PROGRES[6]}"

# Instalasi Expect
echo -e "${GREEN}${PROGRES[7]}${NC}"
sudo apt install -y expect > /dev/null 2>&1 || error_message "${PROGRES[7]}"

# Instalasi OpenSSH Server
echo -e "${GREEN}${PROGRES[8]}${NC}"
sudo apt install -y openssh-server > /dev/null 2>&1 || error_message "${PROGRES[8]}"

# Mengizinkan SSH melalui firewall
sudo ufw allow 22/tcp > /dev/null 2>&1 || error_message "Firewall SSH"

# Mengaktifkan dan menjalankan SSH
sudo systemctl enable --now ssh > /dev/null 2>&1 || error_message "Mengaktifkan SSH"

# Pastikan SSH berjalan
sudo systemctl restart ssh > /dev/null 2>&1 || error_message "Memulai ulang SSH"

# Menambahkan IP Route
echo "Menambahkan IP Route"
sudo ip route add 10.10.10.0/24 via 192.168.22.1 || success_message "IP Route sudah ada"

# Selesai
echo -e "${GREEN}Skrip selesai dengan sukses!${NC}"
