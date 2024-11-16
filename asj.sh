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

# Konfigurasi DHCP
echo "Mengkonfigurasi DHCP..."
sudo bash -c 'cat > /etc/dhcp/dhcpd.conf' << EOF
subnet 192.168.22.0 netmask 255.255.255.0 {
  range 192.168.22.10 192.168.22.100;
  option routers 192.168.22.1;
  option domain-name-servers 8.8.8.8, 8.8.4.4;
}
EOF

# Restart layanan DHCP
sudo systemctl restart isc-dhcp-server

# Konfigurasi VLAN
echo "Mengkonfigurasi VLAN..."
sudo bash -c 'cat > /etc/netplan/01-netcfg.yaml' << EOF
network:
  version: 2
  ethernets:
    eth0:
      dhcp4: no
  vlans:
    eth0.10:
      id: 10
      link: eth0
      addresses: [192.168.22.1/24]
      dhcp4: no
EOF

sudo netplan apply

echo "Mengaktifkan IP forwarding dan pengaturan iptables di Ubuntu Server..."

# Aktifin IP forwarding
echo "Mengaktifkan IP forwarding..."
sudo sysctl -w net.ipv4.ip_forward=1
sudo bash -c 'echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf'

# Konfigurasi NAT biar client dapat akses internet
echo "Mengkonfigurasi NAT..."
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
sudo netfilter-persistent save

echo "Konfigurasi Ubuntu Server suksess WELL."

# Restart DHCP server kanggo nerapkan konfigurasi anyar
echo "🔄 Restart DHCP... tenang, server iki tak pijet sek ben ra spaneng! 😹"
sudo systemctl restart isc-dhcp-server
sudo systemctl status isc-dhcp-server

# 3. Konfigurasi Routing nang Ubuntu Server
echo "🛣️ Gawe routing... datane saiki lancar rek, kayak dalan tol ora ono lampu abang! 🚦"
ip route add 192.168.200.0/24 via $MIKROTIK_IP


# ============================================================
# Skrip Otomasi Konfigurasi Switch
# ============================================================

# ===== Konfigurasi Linux Ubuntu =====
echo "=== Konfigurasi Linux Ubuntu VLAN ==="

# Variabel Ubuntu
PHYSICAL_INTERFACE="eth0"          # Interface fisik
VLAN_ID="10"                       # VLAN ID
VLAN_INTERFACE="${PHYSICAL_INTERFACE}.${VLAN_ID}"
IP_ADDR="192.168.22.1/24"          # IP Address untuk VLAN

# Aktifkan interface fisik
echo "Mengaktifkan interface fisik $PHYSICAL_INTERFACE..."
sudo ip link set $PHYSICAL_INTERFACE up || { echo "Gagal mengaktifkan $PHYSICAL_INTERFACE"; exit 1; }

# Membuat interface VLAN
echo "Membuat VLAN $VLAN_ID pada $PHYSICAL_INTERFACE..."
sudo ip link add link $PHYSICAL_INTERFACE name $VLAN_INTERFACE type vlan id $VLAN_ID || { echo "Gagal membuat VLAN $VLAN_ID"; exit 1; }

# Menambahkan IP Address ke VLAN
echo "Menambahkan IP Address $IP_ADDR ke $VLAN_INTERFACE..."
sudo ip addr add $IP_ADDR dev $VLAN_INTERFACE || { echo "Gagal menambahkan IP ke VLAN"; exit 1; }

# Mengaktifkan interface VLAN
echo "Mengaktifkan interface VLAN $VLAN_INTERFACE..."
sudo ip link set $VLAN_INTERFACE up || { echo "Gagal mengaktifkan $VLAN_INTERFACE"; exit 1; }

# Verifikasi konfigurasi
echo "Detail konfigurasi VLAN di Ubuntu:"
ip addr show $VLAN_INTERFACE

# ===== Petunjuk Konfigurasi Switch =====
echo ""
echo "=== Petunjuk Konfigurasi Switch VLAN ==="
echo "1. Masuk ke switch Anda (contoh Cisco):"
echo "   vlan $VLAN_ID"
echo "   name VLAN$VLAN_ID"
echo ""
echo "2. Atur port trunk untuk Ubuntu:"
echo "   interface Ethernet0/0"
echo "   switchport mode trunk"
echo "   switchport trunk allowed vlan $VLAN_ID"
echo ""
echo "3. Atur port access untuk MikroTik:"
echo "   interface Ethernet0/1"
echo "   switchport mode access"
echo "   switchport access vlan $VLAN_ID"
echo ""
echo "=== Lanjutkan ke konfigurasi MikroTik ==="


# ============================================================
# Skrip Otomasi Konfigurasi Mikrotik
# ============================================================

# ===== Konfigurasi MikroTik =====
echo ""
echo "=== Konfigurasi MikroTik VLAN ==="
read -p "Masukkan IP MikroTik untuk akses via SSH (contoh: 192.168.200.1): " MIKROTIK_IP
read -p "Masukkan username MikroTik: " MIKROTIK_USER
read -s -p "Masukkan password MikroTik: " MIKROTIK_PASSWORD
echo ""

# Kirim konfigurasi ke MikroTik
sshpass -p "$MIKROTIK_PASSWORD" ssh -o StrictHostKeyChecking=no $MIKROTIK_USER@$MIKROTIK_IP << EOF
/interface vlan
add name=vlan10 vlan-id=$VLAN_ID interface=ether1
/ip address
add address=192.168.200.254/24 interface=vlan10
/ip pool
add name=dhcp_pool_vlan10 ranges=192.168.200.50-192.168.200.200
/ip dhcp-server
add name=dhcp_vlan10 interface=vlan10 address-pool=dhcp_pool_vlan10
/ip dhcp-server network
add address=192.168.200.0/24 gateway=192.168.200.254 dns-server=8.8.8.8
/interface enable vlan10
EOF

if [ $? -eq 0 ]; then
    echo "Konfigurasi MikroTik VLAN berhasil dilakukan!"
else
    echo "Gagal mengonfigurasi MikroTik VLAN. Periksa konektivitas SSH."
    exit 1
fi

# ===== Pengujian Konektivitas =====
echo ""
echo "=== Pengujian Konektivitas ==="

# Uji dari Linux ke MikroTik
echo "Menguji ping dari Linux ke gateway MikroTik..."
ping -c 3 192.168.10.254

if [ $? -eq 0 ]; then
    echo "Ping dari Linux ke MikroTik BERHASIL!"
else
    echo "Ping dari Linux ke MikroTik GAGAL. Periksa konfigurasi VLAN atau IP."
    exit 1
fi

# Instruksi untuk pengujian dari klien MikroTik
echo ""
echo "Silakan uji ping dari klien di MikroTik ke Linux (192.168.10.1)."
echo "Jika ping berhasil, konfigurasi selesai dengan sukses!"