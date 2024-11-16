#!/bin/bash

# Variabel Konfigurasi
VLAN_INTERFACE="eth1.10"
VLAN_ID=10
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

# Pastikan interface fisik aktif
echo "Memastikan interface fisik $PHYSICAL_INTERFACE aktif..."
sudo ip link set $PHYSICAL_INTERFACE up

# Membuat VLAN
echo "Membuat VLAN $VLAN_INTERFACE..."
sudo ip link add link $PHYSICAL_INTERFACE name $VLAN_INTERFACE type vlan id $VLAN_ID

# Menambahkan IP Address ke VLAN
echo "Menambahkan IP Address $IP_ADDR ke $VLAN_INTERFACE..."
sudo ip addr add $IP_ADDR dev $VLAN_INTERFACE

# Mengaktifkan interface VLAN
echo "Mengaktifkan interface VLAN $VLAN_INTERFACE..."
sudo ip link set up dev $VLAN_INTERFACE

# Verifikasi
echo "Konfigurasi selesai. Berikut detail interface VLAN:"
ip addr show $VLAN_INTERFACE

# 2. Konfigurasi DHCP Server
echo "📡 Setting DHCP... IP kudu adil rek, ojok rebutan kayak lek dodolan cilok nang pasar! 😎"
cat <<EOF | sudo tee $DHCP_CONF
# Konfigurasi subnet kanggo VLAN 10
subnet 192.168.22.0 netmask 255.255.255.0 {
    range 192.168.22.10 192.168.22.100;
    option routers 192.168.22.1;
    option subnet-mask 255.255.255.0;
    option domain-name-servers 8.8.8.8, 8.8.4.4;
    option domain-name "example.local";
}
EOF

# Restart layanan DHCP
sudo systemctl restart isc-dhcp-server

cat <<EOF | sudo tee /etc/netplan/01-netcfg.yaml
network:
  version: 2
  ethernets:
    eth0:
     dhcp4: true
    eth1:
      dhcp4: no
  vlans:
     eth1.10:
       id: 10
       link: eth1
       addresses: [192.168.22.1/24]
EOF

sudo netplan apply

# Restart DHCP server kanggo nerapkan konfigurasi anyar
echo "🔄 Restart DHCP... tenang, server iki tak pijet sek ben ra spaneng! 😹"
sudo systemctl restart isc-dhcp-server
sudo systemctl status isc-dhcp-server

# 3. Konfigurasi Routing nang Ubuntu Server
echo "🛣️ Gawe routing... datane saiki lancar rek, kayak dalan tol ora ono lampu abang! 🚦"
ip route add 192.168.200.0/24 via $MIKROTIK_IP

# 4. Konfigurasi Cisco Switch liwat SSH
echo "🤖 Ngobrol karo Cisco Switch... ayo ndang rampung, lek switch iki ojok ngambek! 🥲"
sshpass -p "$PASSWORD_SWITCH" ssh -o StrictHostKeyChecking=no $USER_SWITCH@$SWITCH_IP <<EOF
enable
configure terminal
vlan $VLAN_ID
name VLAN10
exit
interface e0/0
switchport trunk encapsulation dot1q
switchport mode trunk
exit
interface e0/1
switchport mode access
switchport access vlan $VLAN_ID
exit
end
write memory
EOF

# 5. Konfigurasi MikroTik liwat SSH
echo "📡 Saiki giliran MikroTik... ayo bro, iki tak konfigurasi nganggo skill dewa! 💻"
if [ -z "$PASSWORD_MIKROTIK" ]; then
    ssh -o StrictHostKeyChecking=no $USER_MIKROTIK@$MIKROTIK_IP <<EOF
interface vlan add name=vlan10 vlan-id=$VLAN_ID interface=ether1
ip address add address=192.168.22.1/24 interface=vlan10      # Sesuaikan karo IP nang VLAN Ubuntu
ip address add address=192.168.200.1/24 interface=ether2     # IP address MikroTik nang jaringan liyane
ip route add dst-address=192.168.22.0/24 gateway=192.168.6.1
EOF
else
    sshpass -p "$PASSWORD_MIKROTIK" ssh -o StrictHostKeyChecking=no $USER_MIKROTIK@$MIKROTIK_IP <<EOF
interface vlan add name=vlan10 vlan-id=$VLAN_ID interface=ether1
ip address add address=192.168.22.1/24 interface=vlan10      # Sesuaikan karo IP nang VLAN Ubuntu
ip address add address=192.168.200.1/24 interface=ether2     # IP address MikroTik nang jaringan liyane
ip route add dst-address=192.168.22.0/24 gateway=192.168.6.1
EOF
fi

echo "🎉 Skrip rampung! Saiki sampeyan dadi Raja Otomasi, gaspol maneh rek! 👑"
