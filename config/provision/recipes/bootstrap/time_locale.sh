__TIMEZONE__=${__TIMEZONE__:-Etc/UTC}
__LOCALE__=${__LOCALE__:-en_US}

sun.mute "timedatectl set-timezone $__TIMEZONE__"
sun.mute "timedatectl set-local-rtc 0"

case "$OS" in
ubuntu)
  sun.mute "locale-gen $__LOCALE__ $__LOCALE__.UTF-8"
  sun.mute "dpkg-reconfigure locales"
;;
centos)
  sun.mute "localectl set-locale LANG=$__LOCALE__.UTF-8"
;;
esac

sun.install "ntp"

systemctl enable ntpd
systemctl start ntpd
