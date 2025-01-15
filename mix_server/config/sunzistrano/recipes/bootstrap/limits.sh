sun.backup_compare '/etc/pam.d/sshd'
sun.backup_compare '/etc/security/limits.conf'
echo "session    required     pam_limits.so" >> /etc/pam.d/sshd
echo "*               soft    nproc           65536" >> /etc/security/limits.conf
echo "*               hard    nproc           65536" >> /etc/security/limits.conf
echo "*               soft    nofile          65536" >> /etc/security/limits.conf
echo "*               hard    nofile          65536" >> /etc/security/limits.conf

#/proc/sys/fs/file-max = 524288
echo "fs.file-max = 2432476" >> /etc/sysctl.conf
#/proc/sys/fs/inotify/max_user_watches = 8192
echo "fs.inotify.max_user_watches = 524288" >> /etc/sysctl.conf
#/proc/sys/fs/inotify/max_user_instances = 128
echo "fs.inotify.max_user_instances = 256" >> /etc/sysctl.conf
#/proc/sys/fs/inotify/max_queued_events = 16384
echo "fs.inotify.max_queued_events = 32768" >> /etc/sysctl.conf

sysctl -p
