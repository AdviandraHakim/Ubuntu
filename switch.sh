#!/usr/bin/expect
# Debugging output log
log_file debug.log

# Konfigurasi Variabel
set timeout 20
set CISCO_IP "192.168.195.134"
set CISCO_PORT "30013"

# Mulai koneksi Telnet
spawn telnet $CISCO_IP $CISCO_PORT
puts "[INFO] Membuka koneksi Telnet ke $CISCO_IP:$CISCO_PORT"

# Masuk ke mode enable
expect ">" {
    puts "[INFO] Berhasil terhubung, masuk ke mode enable"
    send "enable\r"
} timeout {
    puts "[ERROR] Timeout saat menunggu prompt awal">"
    exit 1
}

# Masuk ke konfigurasi terminal
expect "#" {
    puts "[INFO] Masuk ke konfigurasi terminal"
    send "configure terminal\r"
} timeout {
    puts "[ERROR] Gagal masuk ke mode enable"
    exit 1
}

# Konfigurasi interface Ethernet0/1
expect "(config)#" {
    puts "[INFO] Mengonfigurasi interface Ethernet0/1 sebagai access mode"
    send "interface Ethernet0/1\r"
    expect "(config-if)#" { send "switchport mode access\r" }
    expect "(config-if)#" { send "switchport access vlan 10\r" }
    expect "(config-if)#" { send "no shutdown\r" }
    expect "(config-if)#" { send "exit\r" }
} timeout {
    puts "[ERROR] Timeout saat konfigurasi Ethernet0/1"
    exit 1
}

# Konfigurasi interface Ethernet0/0
expect "(config)#" {
    puts "[INFO] Mengonfigurasi interface Ethernet0/0 sebagai trunk mode"
    send "interface Ethernet0/0\r"
    expect "(config-if)#" { send "switchport trunk encapsulation dot1q\r" }
    expect "(config-if)#" { send "switchport mode trunk\r" }
    expect "(config-if)#" { send "no shutdown\r" }
    expect "(config-if)#" { send "exit\r" }
} timeout {
    puts "[ERROR] Timeout saat konfigurasi Ethernet0/0"
    exit 1
}

# Keluar dari konfigurasi
expect "(config)#" {
    puts "[INFO] Menyelesaikan konfigurasi dan keluar"
    send "exit\r"
}
expect "#" { send "exit\r" }

puts "[INFO] Konfigurasi selesai dengan sukses"
expect eof
