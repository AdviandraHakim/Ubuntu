#!/bin/bash

# Otomasi Dimulai
echo "Otomasi WaK"


# Repo Kartolo
cat <<EOF | sudo tee /etc/apt/sources.list
deb http://kartolo.sby.datautama.net.id/ubuntu/ focal main restricted universe multiverse
deb http://kartolo.sby.datautama.net.id/ubuntu/ focal-updates main restricted universe multiverse
deb http://kartolo.sby.datautama.net.id/ubuntu/ focal-security main restricted universe multiverse
deb http://kartolo.sby.datautama.net.id/ubuntu/ focal-backports main restricted universe multiverse
deb http://kartolo.sby.datautama.net.id/ubuntu/ focal-proposed main restricted universe multiverse
EOF

sudo apt update


# Netplan 
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

#install isc-dhcp-server
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

# Config isc-dhcp-server
echo 'INTERFACESv4="eth1.10"' > /etc/default/isc-dhcp-server
systemctl restart isc-dhcp-server

# Ip forward
sudo sed -i '/^#net.ipv4.ip_forward=1/s/^#//' /etc/sysctl.conf
sudo sysctl -p

# Masquerade 
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
sudo apt install iptables-persistent 

#install expect
sudo apt install expect