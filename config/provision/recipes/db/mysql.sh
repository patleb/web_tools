DB_NAME=<%= sun.db_database %>
DB_USER=<%= sun.db_username %>
DB_PWD=<%= sun.db_password %>
DB_ROOT_PWD=<%= sun.mysql_root_password %>

sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password $DB_ROOT_PWD"
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $DB_ROOT_PWD"
sun.install "mysql-server"
sun.install "mysql-client"
sun.install "libmysqlclient-dev"

sudo -u root mysql -proot -e "create database $DB_NAME;"
sudo -u root mysql -proot -e "create user '$DB_USER'@'localhost' identified by '$DB_PWD';"
sudo -u root mysql -proot -e "grant all privileges on $DB_NAME.* to '$DB_USER'@'%' identified by '$DB_PWD';"
sudo -u root mysql -proot -e "flush privileges;"
