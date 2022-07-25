pgrest=${pgrest:-6.0.2}
PACKAGE_NAME="postgrest-v${pgrest}-ubuntu"

wget -q "https://github.com/PostgREST/postgrest/releases/download/v${pgrest}/$PACKAGE_NAME.tar.xz"
tar Jxf "$PACKAGE_NAME.tar.xz"
mkdir -p /opt/pgrest/bin
mv postgrest /opt/pgrest/bin

sun.copy '/etc/systemd/system/pgrest.service'

if [[ "${env}" == 'vagrant' ]]; then
  ufw allow 4000/tcp
  ufw reload
fi

systemctl enable pgrest
systemctl start pgrest
