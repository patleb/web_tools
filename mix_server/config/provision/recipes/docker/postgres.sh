POSTGRESQL_SERVICE_DIR='/etc/systemd/system/postgresql.service.d'
PG_VERSION=$(sun.installed_version 'postgresql')
PG_MAJOR=$(sun.major_version "$PG_VERSION")
PG_CONF="/etc/postgresql/$PG_MAJOR/main/postgresql.conf"
PG_HBA="/etc/postgresql/$PG_MAJOR/main/pg_hba.conf"
PRIVATE_IP=$(sun.private_ip)
DOCKER_BRIDGE=$(ifconfig docker0 | grep "inet addr:" | awk '{print $2}' | sed "s/.*://")

echo "listen_addresses = 'localhost, $DOCKER_BRIDGE'" >> "$PG_CONF"
echo "host    all             all             172.17.0.0/16            md5" >> "$PG_HBA"
echo "host    all             all             172.18.0.0/16            md5" >> "$PG_HBA"
echo "host    all             all             $PRIVATE_IP/32           md5" >> "$PG_HBA"

ufw allow in from 172.17.0.0/16 to $DOCKER_BRIDGE port 5432
ufw allow in from 172.18.0.0/16 to $DOCKER_BRIDGE port 5432
ufw reload

systemctl restart postgresql

mkdir -p $POSTGRESQL_SERVICE_DIR
sun.move "$POSTGRESQL_SERVICE_DIR/reload.conf"

systemctl enable postgresql_restart
