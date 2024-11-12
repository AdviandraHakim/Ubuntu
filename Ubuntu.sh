#!/bin/bash

# Variabel Konfigurasi
INTERFACE="eth0"                   # Interface jaringan yang akan digunakan untuk DHCP
DHCP_CONF="/etc/dhcp/dhcpd.conf"   # Lokasi file konfigurasi DHCP
SUBNET="192.168.1.0"               # Subnet yang akan digunakan
NETMASK="255.255.255.0"            # Netmask
RANGE_START="192.168.1.100"        # IP pertama yang akan diberikan oleh DHCP
RANGE_END="192.168.1.200"          # IP terakhir yang akan diberikan oleh DHCP
ROUTER="192.168.1.1"               # Default Gateway
DNS_SERVERS="8.8.8.8, 8.8.4.4"     # DNS Server
LEASE_TIME="600"                   # Waktu sewa IP dalam detik (misalnya 10 menit)

# 1. Instalasi ISC DHCP Server
echo "Instalasi ISC DHCP Server..."
sudo apt update
sudo apt install -y isc-dhcp-server

# 2. Konfigurasi DHCP Server
echo "Mengonfigurasi DHCP Server..."

cat <<EOL | sudo tee $DHCP_CONF
# File konfigurasi ISC DHCP Server

# Definisikan subnet dan pengaturan DHCP
subnet $SUBNET netmask $NETMASK {
    range $RANGE_START $RANGE_END;   # Rentang IP yang akan diberikan DHCP
    option routers $ROUTER;          # Default gateway
    option domain-name-servers $DNS_SERVERS;  # DNS Server
    option domain-name "local";      # Nama domain lokal
    default-lease-time $LEASE_TIME; # Waktu sewa default (dalam detik)
    max-lease-time 7200;            # Waktu sewa maksimum (dalam detik)
}
EOL

# 3. Tentukan interface yang akan digunakan oleh DHCP Server
echo "Menentukan interface untuk DHCP Server..."
echo "INTERFACESv4=\"$INTERFACE\"" | sudo tee /etc/default/isc-dhcp-server

# 4. Memulai dan Mengaktifkan DHCP Server
echo "Memulai DHCP Server dan mengaktifkan layanan..."
sudo systemctl start isc-dhcp-server
sudo systemctl enable isc-dhcp-server

# 5. Memeriksa status DHCP Server
echo "Memeriksa status DHCP Server..."
sudo systemctl status isc-dhcp-server

# 6. Mengaktifkan IP forwarding jika diperlukan (untuk router atau gateway)
echo "Mengaktifkan IP forwarding..."
sudo sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# 7. Memeriksa Konfigurasi
echo "Verifikasi konfigurasi DHCP Server..."
sudo cat $DHCP_CONF

echo "Konfigurasi DHCP server selesai."
