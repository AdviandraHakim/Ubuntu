from netmiko import ConnectHandler, NetMikoTimeoutException, NetMikoAuthenticationException

# Konfigurasi detail koneksi ke switch
switch_config = {
    'device_type': 'cisco_ios',
    'host': '192.168.22.1',         # Ganti dengan IP switch
    'username': 'cisco',            # Ganti dengan username
    'password': 'password_switch',  # Ganti dengan password
    'secret': 'password_switch',    # Password enable (jika ada)
    'port': 22,                     # Port SSH (default: 22)
}

# Parameter VLAN
vlan_id = 10
vlan_name = "VLAN10"
vlan_ip = "192.168.22.254"
subnet_mask = "255.255.255.0"
access_port = "Ethernet0/1"  # Port yang akan dijadikan access VLAN 10
trunk_port = "Ethernet0/0"   # Port trunk untuk VLAN

# Daftar perintah konfigurasi
config_commands = [
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
    "write memory",
]

def configure_switch():
    try:
        print("Menghubungkan ke switch...")
        connection = ConnectHandler(**switch_config)

        # Masuk ke mode privileged EXEC (enable mode)
        connection.enable()

        print("Koneksi berhasil! Memulai konfigurasi...")
        # Kirim setiap perintah dalam daftar konfigurasi
        for command in config_commands:
            print(f"Menjalankan: {command}")
            output = connection.send_config_set([command])
            print(output)

        print("Konfigurasi selesai. Menyimpan konfigurasi...")
        # Simpan konfigurasi
        save_output = connection.send_command("write memory")
        print(save_output)

        # Tutup koneksi
        connection.disconnect()
        print("Koneksi ditutup.")
    except NetMikoTimeoutException:
        print("Kesalahan: Tidak dapat terhubung ke switch. Periksa IP address atau jaringan.")
    except NetMikoAuthenticationException:
        print("Kesalahan: Autentikasi gagal. Periksa username/password.")
    except Exception as e:
        print(f"Kesalahan lain: {e}")

# Eksekusi fungsi konfigurasi
if __name__ == "__main__":
    configure_switch()
