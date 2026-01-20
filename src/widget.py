from PyQt5 import QtWidgets
from PyQt5.QtWidgets import QApplication, QWidget, QVBoxLayout, QHBoxLayout, QGridLayout, QLabel, QSlider, QPushButton, QScrollArea
from PyQt5.QtCore import Qt
import config
import os
import json

class App(QWidget):
    def __init__(self):
        super().__init__()
        self.initUI()

    def initUI(self):
        self.setWindowTitle('Deskly')
        self.setFixedSize(900, 700)
        self.setStyleSheet("background-color: #2E2E2E;")

        container_layout = QVBoxLayout(self)
        container_layout.setContentsMargins(0, 0, 0, 0)

        scroll = QScrollArea()
        scroll.setWidgetResizable(True)
        scroll.setStyleSheet("""
            QScrollArea {
                border: none;
                background-color: transparent;
            }
            QScrollBar:vertical {
                background-color: #2E2E2E;
                width: 12px;
                border-radius: 6px;
            }
            QScrollBar::handle:vertical {
                background-color: #5E5E5E;
                border-radius: 6px;
            }
            QScrollBar::handle:vertical:hover {
                background-color: #7E7E7E;
            }
        """)

        scroll_widget = QWidget()
        scroll_widget.setStyleSheet("background-color: transparent;")
        main_layout = QGridLayout(scroll_widget)
        main_layout.setSpacing(10)
        main_layout.setContentsMargins(10, 10, 10, 10)

        element_count = 0
        for row in range(10):
            for col in range(4):
                button_div = QWidget()
                button_div.setFixedSize(210, 150)
                button_div.setStyleSheet("background-color: #3E3E3E; border-radius: 10px;")
                button_layout = QVBoxLayout(button_div)
                button = QPushButton(f"Element {element_count + 1}")
                button.setStyleSheet("""
                    QPushButton {
                        background-color: #4E4E4E;
                        color: white;
                        border: none;
                        border-radius: 5px;
                        padding: 10px;
                        font-size: 14px;
                    }
                    QPushButton:hover {
                        background-color: #6E6E6E;
                    }
                    QPushButton:pressed {
                        background-color: #8E8E8E;
                    }
                """)
                button.clicked.connect(lambda checked, num=element_count: self.on_click(num))
                button_layout.addWidget(button)
                main_layout.addWidget(button_div, row, col)
                element_count += 1

        scroll.setWidget(scroll_widget)
        container_layout.addWidget(scroll)
        self.show()

    def on_click(self, button_num):
        conky_file = config.create_conky_file(button_num)
        config.run_conky(conky_file)

if __name__ == '__main__':
    import sys
    app = QApplication(sys.argv)
    ex = App()
    sys.exit(app.exec_())