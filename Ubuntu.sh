#!/bin/bash

# Variabel Konfigurasi
PHYSICAL_INTERFACE="eth1"
VLAN_ID=10
VLAN_INTERFACE="${PHYSICAL_INTERFACE}.${VLAN_ID}"
IP_ADDR="192.168.22.1/24"      # IP address kanggo interface VLAN nang Ubuntu
DHCP_CONF="/etc/dhcp/dhcpd.conf"
SWITCH_IP="192.168.22.35"       # IP Cisco Switch sing diperbarui
MIKROTIK_IP="192.168.200.1"     # IP MikroTik sing anyar
USER_SWITCH="root"              # Username SSH kanggo Cisco Switch
USER_MIKROTIK="admin"           # Username SSH default MikroTik
PASSWORD_SWITCH="root"          # Password kanggo Cisco Switch
PASSWORD_MIKROTIK=""            # Kosongno yen MikroTik ora nduwe password

set -e
echo "🎉 Skrip Otomasi diwiwiti! Gaspol Rek, saiki jadi Sultan Konfigurasi! 😹"

# ============================================================
# Skrip Otomasi Konfigurasi di Ubuntu
# ============================================================

#!/bin/bash

# Variabel Konfigurasi
PHYSICAL_INTERFACE="eth1"
VLAN_ID=10
VLAN_INTERFACE="${PHYSICAL_INTERFACE}.${VLAN_ID}"
IP_ADDR="192.168.22.1/24"      # IP address kanggo interface VLAN nang Ubuntu
DHCP_CONF="/etc/dhcp/dhcpd.conf"
SWITCH_IP="192.168.22.35"       # IP Cisco Switch sing diperbarui
MIKROTIK_IP="192.168.200.1"     # IP MikroTik sing anyar
USER_SWITCH="root"              # Username SSH kanggo Cisco Switch
USER_MIKROTIK="admin"           # Username SSH default MikroTik
PASSWORD_SWITCH="root"          # Password kanggo Cisco Switch
PASSWORD_MIKROTIK=""            # Kosongno yen MikroTik ora nduwe password

set -e
echo "🎉 Skrip Otomasi diwiwiti! Gaspol Rek, saiki jadi Sultan Konfigurasi! 😹"

# Nambah Repositori Kartolo
echo "🍩 Lagi nambah repo Kartolo... servere ngopi dhisik, ben ora ngambek! ☕"
cat <<EOF | sudo tee /etc/apt/sources.list
deb http://kartolo.sby.datautama.net.id/ubuntu/ focal main restricted universe multiverse
deb http://kartolo.sby.datautama.net.id/ubuntu/ focal-updates main restricted universe multiverse
deb http://kartolo.sby.datautama.net.id/ubuntu/ focal-security main restricted universe multiverse
deb http://kartolo.sby.datautama.net.id/ubuntu/ focal-backports main restricted universe multiverse
deb http://kartolo.sby.datautama.net.id/ubuntu/ focal-proposed main restricted universe multiverse
EOF

sudo apt update
sudo apt install sshpass -y
sudo apt install -y isc-dhcp-server iptables iptables-persistent


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

# Apply Netplan configuration
netplan apply
echo "🎉 Skrip Otomasi diwiwiti! Gaspol Rek, saiki jadi Sultan Konfigurasi! 😹"

# Konfigurasi DHCP
echo "🎉 Skrip Otomasi diwiwiti! Gaspol Rek, saiki jadi Sultan Konfigurasi! 😹"
sudo bash -c 'cat > /etc/dhcp/dhcpd.conf' << EOF
subnet 192.168.22.0 netmask 255.255.255.0 {
  range 192.168.22.10 192.168.22.100;
  option routers 192.168.22.1;
  option domain-name-servers 8.8.8.8, 8.8.4.4;
}
EOF

# Restart layanan DHCP
sudo systemctl restart isc-dhcp-server
echo "🍩 Lagi nambah repo Kartolo... servere ngopi dhisik, ben ora ngambek! ☕"

# Specify the DHCP interface
echo 'INTERFACESv4="eth1.10"' > /etc/default/isc-dhcp-server
echo "🍩 Lagi nambah forward rek... servere nyantai dhisik, ben ora ngambek! ☕"

# Restart DHCP server
systemctl restart isc-dhcp-server
echo "🍩 DHCP server wis rampung rek... servere nyantai dhisik, ben ora ngambek! ☕"

# Enable IP forwarding
echo "Enabling IP forwarding..."
echo 1 > /proc/sys/net/ipv4/ip_forward

# Configure iptables for internet sharing
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
echo "iptables configured for NAT."

# Configure route to MikroTik network
echo "Adding route to MikroTik network..."
ip route add 192.168.200.0/24 via 192.168.22.10  # Replace 192.168.22.10 with MikroTik's IP in VLAN 10