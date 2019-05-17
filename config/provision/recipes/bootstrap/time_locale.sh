TIMEZONE=<%= @sun.timezone || 'Etc/UTC' %>
LOCALE=<%= @sun.locale || 'en_US' %>

sun.mute "timedatectl set-timezone $TIMEZONE"
sun.mute "timedatectl set-local-rtc 0"

case "$OS" in
ubuntu)
  sun.mute "locale-gen $LOCALE $LOCALE.UTF-8"
  sun.mute "dpkg-reconfigure locales"
;;
centos)
  sun.mute "localectl set-locale LANG=$LOCALE.UTF-8"
;;
esac

sun.install "curl"
sun.install "ntp"

systemctl enable ntpd
systemctl start ntpd
