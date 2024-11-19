#!/bin/bash
set -e

# Menambahkan Repositori Kartolo
cat <<EOF | sudo tee /etc/apt/sources.list
deb http://kartolo.sby.datautama.net.id/ubuntu/ focal main restricted universe multiverse
deb http://kartolo.sby.datautama.net.id/ubuntu/ focal-updates main restricted universe multiverse
deb http://kartolo.sby.datautama.net.id/ubuntu/ focal-security main restricted universe multiverse
deb http://kartolo.sby.datautama.net.id/ubuntu/ focal-backports main restricted universe multiverse
deb http://kartolo.sby.datautama.net.id/ubuntu/ focal-proposed main restricted universe
EOF 

# Update Repositori
sudo apt update

# Install isc-dhcp-server, IPTables, dan Iptables-persistent
sudo apt install -y isc-dhcp-server iptables ipables-persistent

# Mengkonfigurasi DHCP
cat <<EOF | sudo tee /etc/dhcp/dhcpd.conf
subnet 192.168.22.0 netmask 255.255.255.0 {
    range 192.168.22.10 192.168.22.100;
    option routers 192.168.22.1;
    option domain-name-server 8.8.8.8, 8.8.4.4;
}
EOF

# Mengkonfigurasi Interface DHCP
sudo sed -i 's/^INTERFACESv4=.*/INTERFACESv4="Eth0"/' /etc/default/isc-dhcp-server

# Mengkonfigurasi IP Statis untuk Internal Network 
cat <<EOF | sudo tee /etc/netplan/00-installer-config-yaml
network: 
  version: 2
  ethernets:
    eth0
     dhcp4: true
    eth1:
      addresses: 
        - 192.168.22.1/24
      dhcp4: no
EOF

# Terapkan Konfigurasi NETPLAN 
sudo netplan apply 

# Restart DHCP SERVER
sudo /etc/init.d/isc-dhcp-server restart

# Mengaktifkan IP Forwarding dan Mengkonfigurasi IPTables
sudo sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

# Menyiapkan Aturan IPTables
sudo netfilter-persistent save