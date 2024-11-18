
# ============================================================
# Skrip Otomasi Konfigurasi Switch
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
sudo ip link set $PHYSICAL_INTERFACE up 
echo -e "${GREEN}Berhasil mengaktifkan iterface fisik${NC}"

# Membuat interface VLAN
sudo ip link add link $PHYSICAL_INTERFACE name $VLAN_INTERFACE type vlan id $VLAN_ID 
echo -e "${GREEN}Berhasil membuat vlan${NC}"

# Menambahkan IP Address ke VLAN
sudo ip addr add $IP_ADDR dev $VLAN_INTERFACE 
echo -e "${GREEN}Berhasil menambahkan ip address${NC}"

# Mengaktifkan interface VLAN
sudo ip link set $VLAN_INTERFACE up 
echo -e "${GREEN}Berhasil mengaktifkan interface vlan${NC}"

# Verifikasi konfigurasi
ip addr show $VLAN_INTERFACE
echo -e "${GREEN}untuk detail konfigurasi vlan${NC}"

