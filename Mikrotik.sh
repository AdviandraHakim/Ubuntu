# ============================================================
# Skrip Otomasi Konfigurasi Mikrotik
# ============================================================

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
RED='\033[0;32m'
NC='\033[0m' # No Color

# Variabel Konfigurasi
MIKROTIK_IP="192.168.200.1"     # IP MikroTik sing anyar
USER_MIKROTIK="admin"           # Username SSH default MikroTik
PASSWORD_MIKROTIK=""            # Kosongno yen MikroTik ora nduwe password
VLAN_ID=10

#install sshpass
sudo apt install sshpass -y

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
    echo -e "${GREEN}Berhasil konfigurasi mikrotik vlan${NC}"
    echo -e "${RED}jika gagal berhasil konfigurasi mikrotik vlan${NC}"
    
else
    echo -e "${GREEN}Berhasil konfigurasi mikrotik vlan${NC}"
    echo -e "${RED}jika gagal berhasil konfigurasi mikrotik vlan${NC}"
    exit 1
fi

# ===== Pengujian Konektivitas =====
echo ""
echo "=== Pengujian Konektivitas ==="

# Uji dari Linux ke MikroTik
echo "Menguji ping dari Linux ke gateway MikroTik..."
ping -c 3 192.168.22.254

if [ $? -eq 0 ]; then
    echo "Ping dari Linux ke MikroTik BERHASIL!"
else
    echo "Ping dari Linux ke MikroTik GAGAL. Periksa konfigurasi VLAN atau IP."
    exit 1
fi

# Instruksi untuk pengujian dari klien MikroTik
echo ""
echo "Silakan uji ping dari klien di MikroTik ke Linux (192.168.22.1)."
echo "Jika ping berhasil, konfigurasi selesai dengan sukses!"
