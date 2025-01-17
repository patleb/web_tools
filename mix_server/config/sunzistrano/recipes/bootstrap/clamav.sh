# TODO https://github.com/chainguard-dev/malcontent
sun.install "clamav"
sun.install "clamav-daemon"

sun.service_enable clamav-freshclam
sun.service_disable clamav-daemon
