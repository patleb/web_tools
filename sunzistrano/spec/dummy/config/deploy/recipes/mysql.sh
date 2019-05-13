DB_NAME=<%= @config.db_database %>
DB_USER=<%= @config.db_username %>
DB_PWD=<%= @config.db_password %>
DB_ROOT_PWD=<%= @config.mysql_root_password %>

if sunzi.to_be_done "install mysql"; then
  sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password $DB_ROOT_PWD"
  sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $DB_ROOT_PWD"
  sunzi.install "mysql-server"
  sunzi.install "mysql-client"
  sunzi.install "libmysqlclient-dev"

  sudo -u root mysql -proot -e "create database $DB_NAME;"
  sudo -u root mysql -proot -e "create user '$DB_USER'@'localhost' identified by '$DB_PWD';"
  sudo -u root mysql -proot -e "grant all privileges on $DB_NAME.* to '$DB_USER'@'%' identified by '$DB_PWD';"
  sudo -u root mysql -proot -e "flush privileges;"

  sunzi.done "install mysql"
fi
