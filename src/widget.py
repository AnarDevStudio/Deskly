from PyQt5 import QtWidgets
from PyQt5.QtWidgets import QApplication, QWidget, QVBoxLayout, QHBoxLayout, QGridLayout, QLabel, QSlider, QPushButton, QScrollArea
from PyQt5.QtGui import QPixmap, QFont, QColor, QPalette
from PyQt5.QtCore import Qt, QPropertyAnimation, QEasingCurve, QPoint
import config


class App(QWidget):
    def __init__(self):
        super().__init__()
        self.initUI()

    def initUI(self):
        self.setWindowTitle('Deskly')
        self.setFixedSize(900, 700)
        self.setStyleSheet("""
            QWidget {
                background-color: qlineargradient(x1:0, y1:0, x2:1, y2:1,
                    stop:0 #1a1a2e, stop:1 #16213e);
            }
        """)

        container_layout = QVBoxLayout(self)
        container_layout.setContentsMargins(0, 0, 0, 0)

        # Header
        header = QWidget()
        header.setFixedHeight(80)
        header.setStyleSheet("""
            background-color: rgba(30, 30, 46, 0.8);
            border-bottom: 2px solid #0f4c75;
        """)
        header_layout = QVBoxLayout(header)
        
        title = QLabel("Deskly")
        title.setAlignment(Qt.AlignCenter)
        title.setStyleSheet("""
            color: #bbe1fa;
            font-size: 32px;
            font-weight: bold;
            font-family: 'Segoe UI', Arial;
            letter-spacing: 2px;
        """)
        
        subtitle = QLabel("Choose Your Desktop Style")
        subtitle.setAlignment(Qt.AlignCenter)
        subtitle.setStyleSheet("""
            color: #7ea8be;
            font-size: 14px;
            font-family: 'Segoe UI', Arial;
        """)
        
        header_layout.addWidget(title)
        header_layout.addWidget(subtitle)
        container_layout.addWidget(header)

        scroll = QScrollArea()
        scroll.setWidgetResizable(True)
        scroll.setStyleSheet("""
            QScrollArea {
                border: none;
                background-color: transparent;
            }
            QScrollBar:vertical {
                background-color: rgba(30, 30, 46, 0.5);
                width: 14px;
                border-radius: 7px;
                margin: 2px;
            }
            QScrollBar::handle:vertical {
                background-color: qlineargradient(x1:0, y1:0, x2:1, y2:0,
                    stop:0 #0f4c75, stop:1 #3282b8);
                border-radius: 7px;
                min-height: 30px;
            }
            QScrollBar::handle:vertical:hover {
                background-color: qlineargradient(x1:0, y1:0, x2:1, y2:0,
                    stop:0 #3282b8, stop:1 #bbe1fa);
            }
            QScrollBar::add-line:vertical, QScrollBar::sub-line:vertical {
                height: 0px;
            }
        """)

        scroll_widget = QWidget()
        scroll_widget.setStyleSheet("background-color: transparent;")
        main_layout = QGridLayout(scroll_widget)
        main_layout.setSpacing(20)
        main_layout.setContentsMargins(20, 20, 20, 20)

        element_count = 0
        for row in range(5):
            for col in range(3):
                logo = QPixmap("./styles/images.jpeg")
                
                button_div = QWidget()
                button_div.setFixedSize(270, 230)
                button_div.setStyleSheet("""
                    background-color: rgba(46, 46, 66, 0.6);
                    border-radius: 15px;
                    border: 2px solid rgba(50, 130, 184, 0.3);
                """)
                
                style_name = QLabel("Normal Style", button_div)
                style_name.setGeometry(0, 10, 270, 35)
                style_name.setAlignment(Qt.AlignCenter)
                style_name.setStyleSheet("""
                    color: #bbe1fa;
                    font-size: 16px;
                    font-weight: bold;
                    font-family: 'Segoe UI', Arial;
                    background-color: transparent;
                    border: none;
                """)
                
                image_container = QWidget(button_div)
                image_container.setGeometry(10, 45, 250, 120)
                image_container.setStyleSheet("""
                    background-color: rgba(30, 30, 46, 0.8);
                    border-radius: 10px;
                    border: 1px solid rgba(50, 130, 184, 0.2);
                """)
                
                image_label = QLabel(image_container)
                image_label.setGeometry(5, 5, 240, 110)
                image_label.setAlignment(Qt.AlignCenter)
                image_label.setPixmap(logo.scaled(240, 110, Qt.KeepAspectRatio, Qt.SmoothTransformation))
                image_label.setStyleSheet("background-color: transparent; border: none;")
                
                # Button
                button = QPushButton(f"Apply Style {element_count + 1}", button_div)
                button.setGeometry(30, 180, 210, 40)
                button.setStyleSheet("""
                    QPushButton {
                        background-color: qlineargradient(x1:0, y1:0, x2:1, y2:0,
                            stop:0 #0f4c75, stop:1 #3282b8);
                        color: #bbe1fa;
                        border: none;
                        border-radius: 8px;
                        padding: 10px;
                        font-size: 14px;
                        font-weight: bold;
                        font-family: 'Segoe UI', Arial;
                    }
                    QPushButton:hover {
                        background-color: qlineargradient(x1:0, y1:0, x2:1, y2:0,
                            stop:0 #3282b8, stop:1 #5dade2);
                        border: 2px solid #bbe1fa;
                    }
                    QPushButton:pressed {
                        background-color: qlineargradient(x1:0, y1:0, x2:1, y2:0,
                            stop:0 #1b262c, stop:1 #0f4c75);
                    }
                """)
                button.setCursor(Qt.PointingHandCursor)
                button.clicked.connect(lambda checked, num=element_count: self.on_click(num))
                
                main_layout.addWidget(button_div, row, col)
                element_count += 1

        scroll.setWidget(scroll_widget)
        container_layout.addWidget(scroll)
        self.show()

    def on_click(self, button_num):
        conky_file = config.create_conky_file(button_num)
        config.run_conky(conky_file)