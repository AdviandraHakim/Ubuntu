#!/bin/bash

# ============================================================
# Skrip Otomasi Konfigurasi VLAN 10 di Ubuntu, Cisco Switch, & MikroTik
# ============================================================

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

# Variabel untuk progres
PROGRES=("Menambahkan Repository Kymm" "Melakukan update paket" "Mengonfigurasi netplan" "Menginstal DHCP server" \
         "Mengonfigurasi DHCP server" "Mengaktifkan IP Forwarding" "Mengonfigurasi Masquerade" \
         "Menginstal iptables-persistent" "Menyimpan konfigurasi iptables"  \
         "Membuat iptables NAT Service" "Menginstal Expect" "Konfigurasi Cisco" "Konfigurasi Mikrotik")

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
    sudo bash -c "cat >> /etc/apt/sources.list" <<EOF
deb ${REPO} focal main restricted universe multiverse
deb ${REPO} focal-updates main restricted universe multiverse
deb ${REPO} focal-security main restricted universe multiverse
deb ${REPO} focal-backports main restricted universe multiverse
deb ${REPO} focal-proposed main restricted universe multiverse
EOF
fi

# Update Paket
echo -e "${GREEN}${PROGRES[1]}${NC}"
sudo apt update -y > /dev/null 2>&1 || error_message "Update paket"

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
sudo netplan apply > /dev/null 2>&1 || error_message "Konfigurasi netplan"

# Instalasi ISC DHCP Server
echo -e "${GREEN}${PROGRES[3]}${NC}"
if ! dpkg -l | grep -q isc-dhcp-server; then
    sudo apt update -y > /dev/null 2>&1 || error_message "Update sebelum instalasi DHCP server"
    sudo apt install -y isc-dhcp-server > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        success_message "Instalasi ISC DHCP server"
    else
        error_message "Instalasi ISC DHCP server"
    fi
else
    success_message "ISC DHCP server sudah terinstal"
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
  max-lease-time 7200;

  host kymm {
    hardware ethernet 00:50:79:66:68:0f;  
    fixed-address 192.168.22.10;
  }
}
EOF
echo 'INTERFACESv4="eth1.10"' | sudo tee /etc/default/isc-dhcp-server > /dev/null
sudo systemctl restart isc-dhcp-server > /dev/null 2>&1 || error_message "Konfigurasi DHCP server"

# Aktifkan IP Forwarding
echo -e "${GREEN}${PROGRES[5]}${NC}"
sudo sed -i '/^#net.ipv4.ip_forward=1/s/^#//' /etc/sysctl.conf
sudo sysctl -p > /dev/null 2>&1 || error_message "Aktivasi IP forwarding"

# Konfigurasi Masquerade dengan iptables
echo -e "${GREEN}${PROGRES[6]}${NC}"
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE || error_message "Konfigurasi Masquerade"

# Instalasi iptables-persistent
echo -e "${GREEN}${PROGRES[7]}${NC}"
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | sudo debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean false | sudo debconf-set-selections
sudo apt install -y iptables-persistent > /dev/null 2>&1 || error_message "Instalasi iptables-persistent"

# Menyimpan Konfigurasi iptables
echo -e "${GREEN}${PROGRES[8]}${NC}"
sudo sh -c "iptables-save > /etc/iptables/rules.v4" || error_message "Simpan iptables rules"

# Membuat iptables NAT Service
echo -e "${GREEN}${PROGRES[9]}${NC}"
sudo bash -c 'cat > /etc/systemd/system/iptables-nat.service' << 'EOF'
[Unit]
Description=Setup iptables NAT
After=network.target

[Service]
Type=oneshot
ExecStart=/sbin/iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable iptables-nat > /dev/null 2>&1 || error_message "Membuat NAT service"
sudo systemctl start iptables-nat > /dev/null 2>&1 || error_message "Start NAT service"

# Instalasi Expect
echo -e "${GREEN}${PROGRES[10]}${NC}"
if ! command -v expect > /dev/null; then
    sudo apt install -y expect > /dev/null 2>&1 || error_message "Instalasi Expect"
    success_message "Instalasi Expect"
else
    success_message "Expect sudah terinstal"
fi

# Ip routing 
ip route add 192.168.200.0/24 via 192.168.22.3
ip route add 192.168.200.0/24 via 192.168.22.3
