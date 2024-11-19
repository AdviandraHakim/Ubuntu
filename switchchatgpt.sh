# 2. Konfigurasi Switch Cisco
echo "=== Konfigurasi Switch Cisco ==="
sshpass -p 'password_switch' ssh -o StrictHostKeyChecking=no cisco@192.168.22.X << EOF
enable
configure terminal

# Buat VLAN 10
vlan 10
name VLAN10
exit

# Konfigurasi interface VLAN 10 untuk pengelolaan switch (IP untuk VLAN 10 di switch)
interface vlan 10
ip address 192.168.22.254 255.255.255.0  # IP untuk VLAN 10
no shutdown
exit

# Konfigurasi port untuk VLAN 10 (port akses)
interface e0/1
switchport mode access
switchport access vlan 10
exit

# Konfigurasi port trunk yang menghubungkan ke MikroTik
interface e0/0
switchport mode trunk
exit

# Simpan konfigurasi
write memory
EOF
echo "=== Konfigurasi Switch Cisco Selesai ==="
