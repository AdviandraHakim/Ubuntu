from netmiko import ConnectHandler, NetMikoTimeoutException, NetMikoAuthenticationException

# Konfigurasi detail koneksi ke switch
switch_config = {
    'device_type': 'cisco_ios',
    'host': '192.168.22.1',         # Ganti dengan IP switch
    'username': 'admin',            # Ganti dengan username
    'password': 'adminpassword',    # Ganti dengan password
    'secret': 'adminpassword',      # Password untuk mode enable
    'port': 22,                     # Port SSH (default: 22)
}

# Perintah konfigurasi VLAN
config_commands = [
    "vlan 10",
    "name VLAN10",
    "exit",
    "interface vlan 10",
    "ip address 192.168.22.254 255.255.255.0",
    "no shutdown",
    "exit",
    "interface Ethernet0/1",
    "switchport mode access",
    "switchport access vlan 10",
    "exit",
    "interface Ethernet0/0",
    "switchport mode trunk",
    "switchport trunk allowed vlan 10",
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
        # Kirim setiap perintah konfigurasi
        for command in config_commands:
            print(f"Menjalankan: {command}")
            output = connection.send_config_set([command])
            print(output)

        print("Konfigurasi selesai. Menyimpan konfigurasi...")
        save_output = connection.send_command("write memory")
        print(save_output)

        connection.disconnect()
        print("Koneksi ditutup.")
    except NetMikoTimeoutException:
        print("Kesalahan: Tidak dapat terhubung ke switch. Periksa IP address atau jaringan.")
    except NetMikoAuthenticationException:
        print("Kesalahan: Autentikasi gagal. Periksa username/password.")
    except Exception as e:
        print(f"Kesalahan lain: {e}")

if __name__ == "__main__":
    configure_switch()
