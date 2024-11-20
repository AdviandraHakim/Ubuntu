from netmiko import ConnectHandler

# Konfigurasi detail koneksi ke switch
switch = {
    'device_type': 'cisco_ios',
    'host': '192.168.22.0',  # Ganti dengan IP switch
    'username': 'cisco',     # Ganti dengan username
    'password': 'password_switch',  # Ganti dengan password
    'secret': 'password_switch',    # Enable password (jika ada)
}

# Konfigurasi VLAN
vlan_id = 10
vlan_name = "VLAN10"
vlan_ip = "192.168.22.254"
subnet_mask = "255.255.255.0"
access_port = "Ethernet0/1"  # Port untuk akses VLAN 10
trunk_port = "Ethernet0/0"   # Port untuk trunk VLAN

# Perintah konfigurasi
commands = [
    f"vlan {vlan_id}",
    f"name {vlan_name}",
    "exit",
    f"interface vlan {vlan_id}",
    f"ip address {vlan_ip} {subnet_mask}",
    "no shutdown",
    "exit",
    f"interface {access_port}",
    "switchport mode access",
    f"switchport access vlan {vlan_id}",
    "exit",
    f"interface {trunk_port}",
    "switchport mode trunk",
    f"switchport trunk allowed vlan {vlan_id}",
    "exit",
    "end",
]

# Menghubungkan ke switch dan menjalankan perintah
try:
    print("Menghubungkan ke switch...")
    connection = ConnectHandler(**switch)
    connection.enable()  # Masuk ke mode privileged exec
    print("Koneksi berhasil, mengonfigurasi switch...")
    
    for command in commands:
        output = connection.send_command(command)
        print(f"Menjalankan: {command}\n{output}")
    
    print("Konfigurasi selesai. Menutup koneksi...")
    connection.disconnect()
except Exception as e:
    print(f"Terjadi kesalahan: {e}")
