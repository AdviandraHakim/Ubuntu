
# ============================================================
# Skrip Otomasi Konfigurasi Switch
# ============================================================

# ===== Konfigurasi Linux Ubuntu =====
echo "=== Konfigurasi Linux Ubuntu VLAN ==="

#install sshpass
sudo apt install sshpass -y

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
echo "   enable"
echo "   configuration terminal"
echo ""
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
echo "   write memory"
echo ""
echo "=== Lanjutkan ke konfigurasi MikroTik ==="
