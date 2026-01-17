import subprocess
import widget
import config
from PyQt5.QtWidgets import QApplication

if __name__ == "__main__":
    is_installed = subprocess.call(["dpkg -l | grep conky"], shell=True)
    config.run_conky(config.create_conky_file())
    print(is_installed)
    if is_installed != 0:
        print("Conky yüklü değil, yükleniyor...")
        subprocess.run(["sudo", "apt", "update"])
        subprocess.run(["sudo", "apt", "install", "-y", "conky-all"])
        print("Conky yüklendi.")
    else:
        print("Conky zaten yüklü.")    
    import sys
    app = QApplication(sys.argv)
    ex = widget.App()
    sys.exit(app.exec_())