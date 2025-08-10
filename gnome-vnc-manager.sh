#!/bin/bash
# GNOME + TigerVNC Installer & Uninstaller for Ubuntu 22.x
# Author: Your Name
# Repo: https://github.com/USERNAME/REPO

function install_gnome_vnc() {
    echo "=== Update sistem ==="
    apt update && apt upgrade -y

    echo "=== Install GNOME full desktop (classic mode) ==="
    DEBIAN_FRONTEND=noninteractive apt install ubuntu-desktop -y

    echo "=== Install TigerVNC ==="
    apt install tigervnc-standalone-server -y

    echo "=== Buat folder VNC ==="
    mkdir -p ~/.vnc

    echo "=== Buat password VNC ==="
    vncpasswd

    echo "=== Konfigurasi VNC startup ==="
    cat > ~/.vnc/xstartup <<EOL
#!/bin/bash
export XDG_SESSION_TYPE=x11
export XDG_CURRENT_DESKTOP=GNOME
export GNOME_SHELL_SESSION_MODE=classic
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
exec /usr/bin/gnome-session --session=gnome-classic &
EOL

    chmod +x ~/.vnc/xstartup

    echo "=== Buat systemd service untuk autostart VNC ==="
    cat > /etc/systemd/system/vncserver@.service <<EOL
[Unit]
Description=Start TigerVNC server at startup
After=syslog.target network.target

[Service]
Type=forking
User=root
PAMName=login
PIDFile=/root/.vnc/%H:%i.pid
ExecStartPre=-/usr/bin/vncserver -kill :%i > /dev/null 2>&1
ExecStart=/usr/bin/vncserver :%i -geometry 1366x768 -depth 24
ExecStop=/usr/bin/vncserver -kill :%i

[Install]
WantedBy=multi-user.target
EOL

    echo "=== Aktifkan autostart VNC ==="
    systemctl daemon-reload
    systemctl enable vncserver@1.service
    systemctl start vncserver@1.service

    echo "=== Optimasi GNOME ==="
    gsettings set org.gnome.desktop.interface enable-animations false
    systemctl disable whoopsie apport cups-browsed cups ModemManager avahi-daemon bluetooth
    sysctl vm.swappiness=10
    echo "vm.swappiness=10" >> /etc/sysctl.conf
    sysctl vm.vfs_cache_pressure=50
    echo "vm.vfs_cache_pressure=50" >> /etc/sysctl.conf

    echo "=== Instalasi & optimasi selesai! ==="
    echo "Akses VPS GNOME Desktop via VNC Viewer di IP_VPS:5901"
}

function uninstall_gnome_vnc() {
    echo "=== Menghapus GNOME + VNC ==="
    systemctl stop vncserver@1.service
    systemctl disable vncserver@1.service
    rm -f /etc/systemd/system/vncserver@.service

    apt remove --purge ubuntu-desktop tigervnc-standalone-server -y
    apt autoremove -y
    apt clean

    rm -rf ~/.vnc

    echo "=== Uninstall selesai. GNOME + VNC sudah dihapus ==="
}

echo "Pilih opsi:"
echo "1) Install GNOME + VNC"
echo "2) Uninstall GNOME + VNC"
read -p "Masukkan pilihan [1/2]: " choice

if [ "$choice" == "1" ]; then
    install_gnome_vnc
elif [ "$choice" == "2" ]; then
    uninstall_gnome_vnc
else
    echo "Pilihan tidak valid."
fi
