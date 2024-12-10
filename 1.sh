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

# Variabel progres
PROGRES=("Menambahkan Repository Kartolo" "Melakukan update paket" "Mengonfigurasi netplan" "Menginstal DHCP server" \
         "Mengonfigurasi DHCP server" "Mengaktifkan IP Forwarding" "Mengonfigurasi Masquerade" \
         "Menginstal iptables-persistent" "Menyimpan konfigurasi iptables" "Menginstal Expect")
STEP=0


# Warna untuk output
GREEN='\033[1;32m'
NC='\033[0m'

# Menambahkan Repository Ban
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
sudo apt update -y > /dev/null 2>&1

# Konfigurasi Netplan
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
sudo netplan apply > /dev/null 2>&1

# Instalasi ISC DHCP Server
sudo apt install -y isc-dhcp-server > /dev/null 2>&1

# Konfigurasi DHCP Server
sudo bash -c 'cat > /etc/dhcp/dhcpd.conf' << EOF > /dev/null
subnet 192.168.22.0 netmask 255.255.255.0 {
  range 192.168.22.2 192.168.22.254;
  option domain-name-servers 8.8.8.8;
  option subnet-mask 255.255.255.0;
  option routers 192.168.22.1;
  option broadcast-address 192.168.22.255;
  default-lease-time 600;
  max-lease-time 7200;

  host {
    hardware ethernet 00:50:79:66:68:0f;  
    fixed-address 192.168.22.10;
  }
}
EOF
echo 'INTERFACESv4="eth1.10"' | sudo tee /etc/default/isc-dhcp-server > /dev/null
sudo systemctl restart isc-dhcp-server > /dev/null 2>&1

# Aktifkan IP Forwarding
sudo sed -i '/^#net.ipv4.ip_forward=1/s/^#//' /etc/sysctl.conf
sudo sysctl -p > /dev/null 2>&1

# Konfigurasi Masquerade dengan iptables
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE > /dev/null 2>&1

# Instalasi iptables-persistent dengan otomatisasi
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | sudo debconf-set-selections > /dev/null 2>&1
echo iptables-persistent iptables-persistent/autosave_v6 boolean false | sudo debconf-set-selections > /dev/null 2>&1
sudo apt install -y iptables-persistent > /dev/null 2>&1

# Menyimpan Konfigurasi iptables
sudo sh -c "iptables-save > /etc/iptables/rules.v4" > /dev/null 2>&1
sudo sh -c "ip6tables-save > /etc/iptables/rules.v6" > /dev/null 2>&1

# Membuat iptables NAT Service
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
sudo systemctl enable iptables-nat
sudo systemctl start iptables-nat

# Instalasi Expect
if ! command -v expect > /dev/null; then
    sudo apt install -y expect > /dev/null 2>&1
    [ $? -eq 0 ] && success_message "Instalasi Expect" || error_message "Instalasi Expect"
else
    success_message "Expect sudah terinstal"
fi
# ip routing
sudo systemctl restart isc-dhcp-server

# Instalasi Expect
show_progress
sudo apt install -y expect
ip route add 192.168.200.0/24 via 192.168.22.3
ip route add 192.168.200.0/24 via 192.168.22.3

# Selesai
echo "Otomasi selesai!"
