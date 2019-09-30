__TIMEZONE__=${__TIMEZONE__:-Etc/UTC}
__LOCALE__=${__LOCALE__:-en_US}

sun.mute "timedatectl set-timezone $__TIMEZONE__"
sun.mute "timedatectl set-local-rtc 0"

sun.install "ntp"

if systemctl list-unit-files | grep enabled | grep -Fq systemd-timesyncd; then
  systemctl disable systemd-timesyncd
fi

case "$OS" in
ubuntu)
  sun.mute "locale-gen $__LOCALE__ $__LOCALE__.UTF-8"
  sun.mute "dpkg-reconfigure locales"

  systemctl enable ntp
  systemctl start ntp
;;
centos)
  sun.mute "localectl set-locale LANG=$__LOCALE__.UTF-8"

  systemctl enable ntpd
  systemctl start ntpd
;;
esac
