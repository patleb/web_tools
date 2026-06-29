sun.install "postgresql-common"
yes | sudo /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh $CODE
sun.upgrade "postgresql-common" # update to the most recent apt.postgresql.org.sh
sun.backup_compare /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh

sun.install "postgresql-client"
