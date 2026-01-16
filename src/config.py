import os
import subprocess

def create_deskly_folder():
    home_dir = os.environ.get("HOME") or os.environ.get("USERPROFILE")
    deskly_dir = os.path.join(home_dir, "Deskly")

    if not os.path.exists(deskly_dir):
        os.mkdir(deskly_dir)
        print(f"'{deskly_dir}' klasörü oluşturuldu.")
    else:
        print(f"'{deskly_dir}' klasörü zaten var.")

    return deskly_dir

def create_conky_file():
    deskly_dir = create_deskly_folder()
    conky_path = os.path.join(deskly_dir, ".conkyrc")

    if not os.path.exists(conky_path):
        with open(conky_path, "w") as f:
            f.write(
"""
conky.config = {
    alignment = 'top_right',
    background = true,
    double_buffer = true,
    update_interval = 1.0,
    own_window = true,
    own_window_type = 'normal',
    own_window_transparent = true,
    minimum_width = 300,
    maximum_width = 300,
    gap_x = 20,
    gap_y = 40,
}

conky.text = [[
${time %H:%M:%S}
CPU: ${cpu}%
RAM: ${memperc}%
]]
"""
            )
        print(f"'{conky_path}' dosyası oluşturuldu ve içerik yazıldı.")
    else:
        print(f"'{conky_path}' dosyası zaten mevcut.")
    return conky_path

def install_dependencies():
    subprocess.run(["sudo", "apt", "update"])
    subprocess.run(["sudo", "apt", "install", "-y", "conky-all"])

def run_conky(conky_file):
    # Conky'yi başlat
    print("Conky başlatılıyor...")
    subprocess.Popen(["conky", "-c", conky_file])
    print("Conky çalışıyor!")

if __name__ == "__main__":
    conky_file = create_conky_file()
    run_conky(conky_file)
