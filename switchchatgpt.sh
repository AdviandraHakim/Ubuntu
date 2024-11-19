# ===== Konfigurasi Cisco Switch =====
echo -e "\033[0;32m=== Konfigurasi Switch Cisco ===\033[0m"
SWITCH_IP="192.168.1.100"
SWITCH_USER="admin"
SWITCH_PASS="password"
ACCESS_INTERFACE="FastEthernet0/1"
TRUNK_INTERFACE="FastEthernet0/0"
VLAN_ID=10

/usr/bin/expect <<EOF
spawn ssh $SWITCH_USER@$SWITCH_IP
expect "Password:" { send "$SWITCH_PASS\r" }
expect ">" { send "enable\r" }
expect "#" { send "configure terminal\r" }
expect "(config)#" { send "vlan $VLAN_ID\r" }
expect "(config-vlan)#" { send "exit\r" }
expect "(config)#" { send "interface $ACCESS_INTERFACE\r" }
expect "(config-if)#" { send "switchport mode access\r" }
expect "(config-if)#" { send "switchport access vlan $VLAN_ID\r" }
expect "(config-if)#" { send "exit\r" }
expect "(config)#" { send "interface $TRUNK_INTERFACE\r" }
expect "(config-if)#" { send "switchport mode trunk\r" }
expect "(config-if)#" { send "switchport trunk allowed vlan $VLAN_ID\r" }
expect "(config-if)#" { send "exit\r" }
expect "(config)#" { send "end\r" }
expect "#" { send "write memory\r" }
expect "#" { send "exit\r" }
EOF