# ===== Konfigurasi MikroTik =====
echo -e "\033[0;32m=== Konfigurasi MikroTik ===\033[0m"
read -p "Masukkan IP MikroTik: " MIKROTIK_IP
read -p "Masukkan username MikroTik: " MIKROTIK_USER
read -s -p "Masukkan password MikroTik: " MIKROTIK_PASS

sshpass -p "$MIKROTIK_PASS" ssh -o StrictHostKeyChecking=no $MIKROTIK_USER@$MIKROTIK_IP << EOF
/interface vlan add name=vlan10 vlan-id=10 interface=ether1
/ip address add address=192.168.22.254/24 interface=vlan10
EOF

echo -e "\033[0;32m=== Konfigurasi selesai ===\033[0m"