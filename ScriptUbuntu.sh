#!/bin/bash

# Skrip konfigurasi dimulai
echo "Starting configuration..."

# Step 1: Repo Kartolo
echo "Configuring repositories..."
cat <<EOF | sudo tee /etc/apt/sources.list
deb http://kartolo.sby.datautama.net.id/ubuntu/ focal main restricted universe multiverse
deb http://kartolo.sby.datautama.net.id/ubuntu/ focal-updates main restricted universe multiverse
deb http://kartolo.sby.datautama.net.id/ubuntu/ focal-security main restricted universe multiverse
deb http://kartolo.sby.datautama.net.id/ubuntu/ focal-backports main restricted universe multiverse
deb http://kartolo.sby.datautama.net.id/ubuntu/ focal-proposed main restricted universe multiverse
EOF

sudo apt update

# Step 2: Configure Netplan
echo "Configuring Netplan..."
cat <<EOT | sudo tee /etc/netplan/01-netcfg.yaml
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
sudo netplan apply

# Step 3: Install and configure DHCP server
echo "Installing and configuring DHCP server..."
sudo apt install -y isc-dhcp-server
cat <<EOF | sudo tee /etc/dhcp/dhcpd.conf
# A slightly different configuration for an internal subnet.
subnet 192.168.22.0 netmask 255.255.255.0 {
  range 192.168.22.2 192.168.22.254;
  option domain-name-servers 8.8.8.8;
  option subnet-mask 255.255.255.0;
  option routers 192.168.22.1;
  option broadcast-address 192.168.22.255;
  default-lease-time 600;
  max-lease-time 7200;
}
EOF

# Step 4: Configure DHCP interface
echo "Configuring DHCP interface..."
echo 'INTERFACESv4="eth1.10"' | sudo tee /etc/default/isc-dhcp-server
sudo systemctl restart isc-dhcp-server

# Step 5: Enable IP forwarding
echo "Enabling IP forwarding..."
sudo sed -i '/^#net.ipv4.ip_forward=1/s/^#//' /etc/sysctl.conf
sudo sysctl -p

# Step 6: Configure NAT masquerading
echo "Configuring NAT masquerading..."
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
sudo apt install -y iptables-persistent

# Step 7: Install sshpass
echo "Installing sshpass..."
sudo apt install -y sshpass

# ASCII Art muncul setelah konfigurasi selesai
clear
echo "  ___      _       _ _    _           "
echo " / _ \    | |     (_) |  (_)          "
echo "/ /_\ \ __| |_   ___| | ___ _ __ ___  "
echo "|  _  |/ _\` \ \ / / | |/ / | '_ \` _ \ "
echo "| | | | (_| |\ V /| |   <| | | | | | |"
echo "\_| |_/\__,_| \_/ |_|_|\_\_|_| |_| |_|"
echo "                                      "
echo "Configuration completed successfully!"
