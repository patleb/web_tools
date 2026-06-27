sun.install "postgresql-common"
sun.backup_compare /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh

yes | sudo /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh $CODE
sun.update

sun.install "postgresql-client"
