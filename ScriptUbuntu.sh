#!/bin/bash

# Warna untuk output
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${GREEN}Memulai konfigurasi Ubuntu Server${NC}"

# 1. Mengganti repository menjadi repository lokal Kartolo
echo -e "${GREEN}Mengganti repository ke Kartolo${NC}"
cat <<EOF > /etc/apt/sources.list
deb http://kartolo.sby.datautama.net.id/ubuntu/ focal main restricted universe multiverse
deb http://kartolo.sby.datautama.net.id/ubuntu/ focal-updates main restricted universe multiverse
deb http://kartolo.sby.datautama.net.id/ubuntu/ focal-security main restricted universe multiverse
deb http://kartolo.sby.datautama.net.id/ubuntu/ focal-backports main restricted universe multiverse
deb http://kartolo.sby.datautama.net.id/ubuntu/ focal-proposed main restricted universe
EOF

# Update sistem
apt update &> /dev/null
echo -e "${GREEN}Berhasil mengganti repository dan mengupdate sistem${NC}"

# 2. Install DHCP Server dan iptables-persistent
echo -e "${GREEN}Menginstall DHCP Server dan iptables-persistent${NC}"
apt install -y isc-dhcp-server iptables iptables-persistent &> /dev/null
echo -e "${GREEN}Berhasil menginstall DHCP Server dan iptables-persistent${NC}"

# 3. Konfigurasi Netplan untuk VLAN 10
echo -e "${GREEN}Mengonfigurasi jaringan dengan VLAN 10${NC}"
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
echo -e "${GREEN}Berhasil menerapkan konfigurasi Netplan${NC}"

# 4. Konfigurasi DHCP Server
echo -e "${GREEN}Mengonfigurasi DHCP Server${NC}"
cat <<EOF > /etc/dhcp/dhcpd.conf
# Konfigurasi subnet untuk VLAN 10
subnet 192.168.22.0 netmask 255.255.255.0 {
    range 192.168.22.2 192.168.22.254;
    option domain-name-servers 8.8.8.8;
    option subnet-mask 255.255.255.0;
    option routers 192.168.22.1;
    option broadcast-address 192.168.22.255;
    default-lease-time 600;
    max-lease-time 7200;
}

# Konfigurasi IP statis untuk perangkat tertentu
host fantasia {
    hardware ethernet 00:50:79:66:68:0f;
    fixed-address 192.168.22.10;
}
EOF

# Konfigurasi interface DHCP server
echo 'INTERFACESv4="eth1.10"' > /etc/default/isc-dhcp-server
systemctl restart isc-dhcp-server
echo -e "${GREEN}Berhasil mengkonfigurasi dan me-restart DHCP Server${NC}"

# 5. Aktifkan IP Forwarding
echo -e "${GREEN}Mengaktifkan IP Forwarding${NC}"
sysctl -w net.ipv4.ip_forward=1 &> /dev/null
sed -i '/net.ipv4.ip_forward/d' /etc/sysctl.conf
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf

# 6. Konfigurasi NAT dengan iptables
echo -e "${GREEN}Mengonfigurasi iptables untuk NAT${NC}"
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
iptables -A FORWARD -i eth0 -o eth1.10 -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth1.10 -o eth0 -j ACCEPT

# Simpan aturan iptables agar tetap ada setelah reboot
iptables-save > /etc/iptables/rules.v4
echo -e "${GREEN}Berhasil menyimpan aturan iptables${NC}"

# 7. Restart layanan terkait
echo -e "${GREEN}Me-restart layanan jaringan dan DHCP server${NC}"
systemctl restart isc-dhcp-server
systemctl restart systemd-networkd
echo -e "${GREEN}Berhasil menyelesaikan konfigurasi${NC}"