import os
import subprocess
import json
import time

def create_deskly_folder():
    home_dir = os.environ.get("HOME") or os.environ.get("USERPROFILE")
    deskly_dir = os.path.join(home_dir, "Deskly")

    if not os.path.exists(deskly_dir):
        os.mkdir(deskly_dir)
    else:
        return deskly_dir

    return deskly_dir

def create_conky_file(id):
    deskly_dir = create_deskly_folder()
    conky_path = os.path.join(deskly_dir, ".conkyrc")

    json_path = os.path.join(os.path.dirname(__file__), "styles", "styles.json")

    if not os.path.exists(json_path):
        return []

    with open(json_path, "r") as styles_file:
        styles = json.load(styles_file)
    
    return styles

def create_conky_file(id):
    deskly_dir = create_deskly_folder()
    conky_path = os.path.join(deskly_dir, ".conkyrc")

    styles = get_styles()
    
    if id >= len(styles):
        print(f"Error: Style ID {id} out of range.")
        return None

    with open(conky_path, "w") as f:
        f.write(styles[id]["style"])
        print(f"'.conkyrc' file is writing:\n{styles[id]['style']}")

    return conky_path

def get_styles():
    json_path = os.path.join(os.path.dirname(__file__), "styles", "styles.json")
    if not os.path.exists(json_path):
        return []
        
    with open(json_path, "r") as styles_file:
        return json.load(styles_file)

def install_dependencies():
    subprocess.run(["sudo", "apt", "update"], check=True)
    subprocess.run(["sudo", "apt", "install", "-y", "conky-all"], check=True)

def run_conky(conky_file):
    if conky_file is None:
        return

    subprocess.run(["pkill", "conky"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    time.sleep(0.5)

    # Yeni Conky başlat
    subprocess.Popen(["conky", "-c", conky_file],
                     stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    print("Conky started")
