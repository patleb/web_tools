sun.install "postgresql-common"
yes | sudo /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh $CODE
sun.backup_compare /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh

sun.install "postgresql-client"
