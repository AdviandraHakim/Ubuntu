from netmiko import ConnectHandler, NetMikoTimeoutException, NetMikoAuthenticationException

# Konfigurasi koneksi ke switch
switch_config = {
    'device_type': 'cisco_ios',
    'host': '192.168.20.1',  # Ganti dengan IP switch
    'username': '',          # Biarkan kosong jika belum ada username
    'password': '',          # Biarkan kosong jika belum ada password
    'secret': '',            # Biarkan kosong jika belum ada enable password
    'port': 22,              # Port default SSH
}

# Perintah untuk mengaktifkan SSH secara otomatis
config_commands = [
    "hostname Switch1",                       # Ubah hostname
    "ip domain-name example.com",             # Tentukan domain-name
    "crypto key generate rsa modulus 1024",   # Buat kunci RSA
    "ip ssh version 2",                       # Gunakan SSH versi 2
    "username admin privilege 15 secret adminpassword",  # Buat user admin
    "line vty 0 4",                           # Konfigurasi VTY untuk SSH
    "transport input ssh",                    # Hanya izinkan SSH
    "login local",                            # Gunakan username/password lokal
    "exit",                                   # Keluar dari konfigurasi
    "interface vlan 1",                       # Masukkan VLAN 1
    "ip address 192.168.20.1 255.255.255.0",  # Atur IP VLAN untuk manajemen
    "no shutdown",                            # Aktifkan interface VLAN
    "write memory",                           # Simpan konfigurasi
]

def configure_ssh():
    try:
        print("Menghubungkan ke switch...")
        connection = ConnectHandler(**switch_config)

        # Masuk ke mode enable jika diperlukan
        connection.enable()

        print("Koneksi berhasil! Memulai konfigurasi...")
        # Kirim perintah konfigurasi
        output = connection.send_config_set(config_commands)
        print(output)

        print("Konfigurasi selesai. Menyimpan konfigurasi...")
        save_output = connection.save_config()
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
    configure_ssh()
