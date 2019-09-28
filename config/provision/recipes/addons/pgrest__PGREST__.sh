__PGREST__=${__PGREST__:-6.0.2}

case "$OS" in
ubuntu)
  PACKAGE_NAME="postgrest-v$__PGREST__-ubuntu"
;;
centos)
  PACKAGE_NAME="postgrest-v$__PGREST__-centos7"
;;
esac

wget -q "https://github.com/PostgREST/postgrest/releases/download/v$__PGREST__/$PACKAGE_NAME.tar.xz"
tar Jxf "$PACKAGE_NAME.tar.xz"
mkdir -p /opt/pgrest/bin
mv postgrest /opt/pgrest/bin

sun.move '/etc/systemd/system/pgrest.service'

if [[ "$__STAGE__" == 'vagrant' ]]; then
  ufw allow 4000/tcp
  ufw reload
fi

systemctl enable pgrest
systemctl start pgrest
