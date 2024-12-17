#!/usr/bin/expect

# Mulai sesi telnet ke switch
spawn telnet 192.168.195.134 30013
set timeout 10

# Masuk ke mode enable
puts "[INFO] Masuk ke mode enable."
expect ">" { send "enable\r" }

# Masuk ke konfigurasi terminal
puts "[INFO] Masuk ke konfigurasi terminal."
expect "#" { send "configure terminal\r" }

# Konfigurasi interface Ethernet0/1
puts "[INFO] Mengonfigurasi interface Ethernet0/1 sebagai access mode."
expect "(config)#" { send "interface Ethernet0/1\r" }
expect "(config-if)#" { send "switchport mode access\r" }
expect "(config-if)#" { send "switchport access vlan 10\r" }
expect "(config-if)#" { send "no shutdown\r" }
expect "(config-if)#" { send "exit\r" }

# Konfigurasi interface Ethernet0/0
puts "[INFO] Mengonfigurasi interface Ethernet0/0 sebagai trunk mode."
expect "(config)#" { send "interface Ethernet0/0\r" }
expect "(config-if)#" { send "switchport trunk encapsulation dot1q\r" }
expect "(config-if)#" { send "switchport mode trunk\r" }
expect "(config-if)#" { send "no shutdown\r" }
expect "(config-if)#" { send "exit\r" }

# Keluar konfigurasi
puts "[INFO] Menyelesaikan konfigurasi dan keluar."
expect "(config)#" { send "exit\r" }
expect "#" { send "exit\r" }
expect eof
EOF

echo "[INFO] Konfigurasi selesai."
