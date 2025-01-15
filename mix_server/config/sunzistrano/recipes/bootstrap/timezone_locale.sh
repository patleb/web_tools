timezone=${timezone:-Etc/UTC}

sun.mute "timedatectl set-timezone ${timezone}"
sun.mute "timedatectl set-local-rtc 0"

sun.install "ntpsec"

if systemctl list-unit-files | grep enabled | grep -Fq systemd-timesyncd; then
  systemctl disable systemd-timesyncd
fi

sun.mute "locale-gen ${LOCALE} $LC"
sun.mute "dpkg-reconfigure locales"

sun.service_enable ntpsec
