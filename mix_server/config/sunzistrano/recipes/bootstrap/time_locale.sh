timezone=${timezone:-Etc/UTC}
locale=${locale:-en_US}
LC="${locale}.UTF-8"

sun.mute "timedatectl set-timezone ${timezone}"
sun.mute "timedatectl set-local-rtc 0"

sun.install "ntp"

if systemctl list-unit-files | grep enabled | grep -Fq systemd-timesyncd; then
  systemctl disable systemd-timesyncd
fi

export LANGUAGE=$LC
export LANG=$LC
export LC_ALL=$LC
sun.mute "locale-gen ${locale} $LC"
sun.mute "dpkg-reconfigure locales"

systemctl enable ntp
systemctl start ntp
