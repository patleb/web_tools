sun.install "clamav"
sun.install "clamav-daemon"

systemctl enable clamav-freshclam
systemctl start clamav-freshclam
