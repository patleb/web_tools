# TODO https://github.com/chainguard-dev/malcontent
sun.install "clamav"
sun.install "clamav-daemon"

systemctl enable clamav-freshclam
systemctl start clamav-freshclam

systemctl stop clamav-daemon
systemctl disable clamav-daemon
