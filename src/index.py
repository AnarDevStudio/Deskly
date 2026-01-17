import subprocess
import sys
from PyQt5.QtWidgets import QApplication
import config
import widget

if __name__ == "__main__":
    is_installed = subprocess.call(
        "dpkg -l | grep -q conky",
        shell=True
    )

    if is_installed != 0:
        print("Conky is installing...")
        subprocess.run(["sudo", "apt", "update"])
        subprocess.run(["sudo", "apt", "install", "-y", "conky-all"])
    else:
        print("Conky is already installed.")
    config.create_deskly_folder()
    conky_file = config.create_conky_file()
    config.run_conky(conky_file)

    app = QApplication(sys.argv)
    ex = widget.App()
    sys.exit(app.exec_())
