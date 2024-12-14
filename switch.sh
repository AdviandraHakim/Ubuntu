# Konfigurasi Cisco
CISCO_IP="192.168.195.134"
CISCO_PORT="30013"
expect <<EOF
# Aktifkan log output untuk menampilkan interaksi telnet
log_user 1

# Memulai koneksi telnet
spawn telnet $CISCO_IP $CISCO_PORT

# Tunggu pesan koneksi
set timeout 10
expect {
    "Trying*" {
        # Menangkap pesan Trying
        exp_continue
    }
    "Connected*" {
        # Menangkap pesan Connected
        exp_continue
    }
    "Escape character is" {
        # Menangkap pesan Escape Character
        exp_continue
    }
    ">" {
        puts "Login berhasil ke Cisco Switch."
    }
    timeout {
        puts "Error: Tidak bisa terhubung ke Cisco Switch. Periksa koneksi."
        exit 1
    }
}

# Masuk ke mode enable
expect ">" { 
    send "enable\r"
}

# Masuk ke konfigurasi terminal
expect "#" { 
    send "configure terminal\r"
}

# Konfigurasi Ethernet0/1 sebagai akses VLAN 10
expect "(config)#" { send "interface Ethernet0/1\r" }
expect "(config-if)#" { send "switchport mode access\r" }
expect "(config-if)#" { send "switchport access vlan 10\r" }
expect "(config-if)#" { send "no shutdown\r" }
expect "(config-if)#" { send "exit\r" }

# Konfigurasi Ethernet0/0 sebagai trunk
expect "(config)#" { send "interface Ethernet0/0\r" }
expect "(config-if)#" { send "switchport trunk encapsulation dot1q\r" }
expect "(config-if)#" { send "switchport mode trunk\r" }
expect "(config-if)#" { send "no shutdown\r" }
expect "(config-if)#" { send "exit\r" }

# Keluar dari konfigurasi
expect "(config)#" { send "exit\r" }
expect "#" { send "exit\r" }

# Akhiri sesi
expect eof
EOF
