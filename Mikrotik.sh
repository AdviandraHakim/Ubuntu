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
