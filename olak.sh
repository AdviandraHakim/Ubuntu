#!/bin/bash

# Fungsi untuk mencetak teks di tengah layar
print_center() {
  local termwidth
  local padding
  local message="$1"
  local color="$2"
  termwidth=$(tput cols)
  padding=$(( (termwidth - ${#message}) / 2 ))
  printf "%s%${padding}s%s%s\n" "$color" "" "$message" "$(tput sgr0)"
}

# Warna hijau untuk pesan sukses
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Mengganti repository menjadi repository lokal Kartolo Ubuntu 20.04
cat <<EOF > /etc/apt/sources.list
deb http://kartolo.sby.datautama.net.id/ubuntu/ focal main restricted universe multiverse
deb http://kartolo.sby.datautama.net.id/ubuntu/ focal-updates main restricted universe multiverse
deb http://kartolo.sby.datautama.net.id/ubuntu/ focal-security main restricted universe multiverse
deb http://kartolo.sby.datautama.net.id/ubuntu/ focal-backports main restricted universe multiverse
deb http://kartolo.sby.datautama.net.id/ubuntu/ focal-proposed main restricted universe
EOF

# Update sistem dan install ISC DHCP Server, iptables, dan iptables-persistent
apt update &> /dev/null
apt install -y isc-dhcp-server iptables &> /dev/null
echo -e "${GREEN}Berhasil menginstall ISC DHCP Server dan iptables${NC}"

# Install iptables-persistent tanpa prompt interaktif
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean false | debconf-set-selections
apt install -y iptables-persistent &> /dev/null
echo -e "${GREEN}Berhasil menginstall iptables-persistent ${NC}"

# Konfigurasi Netplan untuk VLAN
cat <<EOT > /etc/netplan/01-netcfg.yaml
network:
  version: 2
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

# Terapkan konfigurasi Netplan
netplan apply &> /dev/null
echo -e "${GREEN}Berhasil menerapkan konfigurasi Netplan${NC}"

# Dhcp
sudo bash -c 'cat > /etc/dhcp/dhcpd.conf' << EOF
# A slightly different configuration for an internal subnet.
subnet 192.168.22.0 netmask 255.255.255.0 {
  range 192.168.22.2 192.168.22.254;
  option domain-name-servers 8.8.8.8;
#  option domain-name "internal.example.org";
  option subnet-mask 255.255.255.0;
  option routers 192.168.22.1;
  option broadcast-address 192.168.22.255;
  default-lease-time 600;
  max-lease-time 7200;
}
EOF

# Fixed IP assignment for specific clients based on MAC address
  host client1 {
    hardware ethernet 00:11:22:33:44:55; # Ganti dengan MAC address asli
    fixed-address 192.168.22.10;
  }
EOF

# Tentukan interface DHCP
echo "INTERFACESv4=\"eth1.10\"" > /etc/default/isc-dhcp-server

# Restart DHCP server untuk menerapkan konfigurasi
systemctl restart isc-dhcp-server &> /dev/null
echo -e "${GREEN}Berhasil mengkonfigurasi dan me-restart DHCP server${NC}"

# Aktifkan IP forwarding
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p &> /dev/null
echo -e "${GREEN}Berhasil mengaktifkan IP forwarding${NC}"

# Konfigurasi NAT dengan iptables
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE &> /dev/null
iptables -A FORWARD -i eth0 -o vlan10 -m state --state RELATED,ESTABLISHED -j ACCEPT &> /dev/null
iptables -A FORWARD -i vlan10 -o eth0 -j ACCEPT &> /dev/null

# Simpan aturan iptables agar tetap ada setelah reboot
iptables-save > /etc/iptables/rules.v4
echo -e "${GREEN}Berhasil mengkonfigurasi iptables dan menyimpan aturan${NC}"

# Restart DHCP server dan network untuk memastikan semua berjalan dengan baik
systemctl restart isc-dhcp-server &> /dev/null
systemctl restart systemd-networkd &> /dev/null
echo -e "${GREEN}Berhasil me-restart layanan jaringan dan DHCP server${NC}"