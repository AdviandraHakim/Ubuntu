#!/bin/bash

# 1. Menambahkan Repository Kartolo
echo "Menambahkan repository Kartolo..."
cat <<EOF | sudo tee /etc/apt/sources.list
deb http://kartolo.sby.datautama.net.id/ubuntu/ focal main restricted universe multiverse
deb http://kartolo.sby.datautama.net.id/ubuntu/ focal-updates main restricted universe multiverse
deb http://kartolo.sby.datautama.net.id/ubuntu/ focal-security main restricted universe multiverse
deb http://kartolo.sby.datautama.net.id/ubuntu/ focal-backports main restricted universe multiverse
deb http://kartolo.sby.datautama.net.id/ubuntu/ focal-proposed main restricted universe multiverse
EOF

sudo apt update

# 2. Konfigurasi Netplan untuk VLAN dan IP Address
echo "Mengkonfigurasi Netplan untuk VLAN dan IP Address..."
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

# 3. Install DHCP Server dan Konfigurasinya
echo "Menginstall dan mengkonfigurasi DHCP Server..."
sudo apt install isc-dhcp-server -y

cat <<EOT > /etc/dhcp/dhcpd.conf
subnet 192.168.20.0 netmask 255.255.255.0 {
  range 192.168.20.100 192.168.20.200;
  option routers 192.168.20.1;
  option subnet-mask 255.255.255.0;
  option domain-name-servers 8.8.8.8, 8.8.4.4;
  option broadcast-address 192.168.20.255;
}
EOT

echo 'INTERFACESv4="eth1.10"' > /etc/default/isc-dhcp-server
sudo systemctl restart isc-dhcp-server
sudo systemctl enable isc-dhcp-server

# 4. Enable IP Forwarding dan NAT
echo "Mengaktifkan IP forwarding dan NAT..."
sudo sed -i '/^#net.ipv4.ip_forward=1/s/^#//' /etc/sysctl.conf
sudo sysctl -p

iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
sudo apt install iptables-persistent -y

# 5. Install sshpass untuk remote akses Cisco dan Mikrotik
echo "Menginstall sshpass untuk remote akses..."
sudo apt install sshpass -y

# Skrip Remote untuk Cisco Switch dan Mikrotik
cat <<'EOT' > /usr/local/bin/remote_devices.sh
#!/bin/bash

# Remote Cisco Switch
CISCO_IP="192.168.20.2"
CISCO_USER="admin"
CISCO_PASS="password"
echo "Remote ke Cisco Switch..."
sshpass -p "$CISCO_PASS" ssh -o StrictHostKeyChecking=no "$CISCO_USER@$CISCO_IP"

# Remote Mikrotik
MIKROTIK_IP="192.168.20.3"
MIKROTIK_USER="admin"
MIKROTIK_PASS="password"
echo "Remote ke Mikrotik..."
sshpass -p "$MIKROTIK_PASS" ssh -o StrictHostKeyChecking=no "$MIKROTIK_USER@$MIKROTIK_IP"
EOT

chmod +x /usr/local/bin/remote_devices.sh

# 6. Konfigurasi Cisco Switch
echo "Mengkonfigurasi Cisco Switch..."
sshpass -p "password" ssh -o StrictHostKeyChecking=no admin@192.168.20.2 <<'EOT'
enable
configure terminal
vlan 10
name VLAN10
exit
interface e0/1
switchport mode access
switchport access vlan 10
no shutdown
exit
interface vlan 10
ip address 192.168.20.2 255.255.255.0
no shutdown
exit
hostname CiscoSwitch
ip domain-name local
crypto key generate rsa modulus 1024
line vty 0 4
transport input ssh
login local
exit
username admin privilege 15 secret password
exit
EOT

# 7. Konfigurasi Mikrotik
echo "Mengkonfigurasi Mikrotik..."
sshpass -p "password" ssh -o StrictHostKeyChecking=no admin@192.168.20.3 <<'EOT'
/interface vlan
add name=vlan10 vlan-id=10 interface=ether1
/ip address
add address=192.168.20.3/24 interface=vlan10
add address=192.168.200.1/24 interface=ether2
/ip route
add gateway=192.168.20.1
/ip firewall nat
add chain=srcnat out-interface=ether1 action=masquerade
/user add name=admin password=password group=full
/ip service set ssh disabled=no
EOT

# 8. Pengujian Akses Remote
echo "Pengujian akses remote..."
/usr/local/bin/remote_devices.sh

echo "Konfigurasi selesai."
