# TODO
# https://zipizap.wordpress.com/2013/11/15/incron/
# https://www.infoq.com/articles/inotify-linux-file-system-event-monitoring
# https://www.linux.com/learn/how-use-incron-monitor-important-files-and-folders
INCRON_CONF="/etc/incron.allow"

sun.install "incron"

sun.backup_compare $INCRON_CONF
echo deployer >> $INCRON_CONF

systemctl start incron.service

# /run/nginx.pid IN_DELETE echo "$# $@"
