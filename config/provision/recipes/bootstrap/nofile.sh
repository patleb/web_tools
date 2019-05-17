# /etc/systemd/system/nginx.service.d/nofile.conf
#
# [Service]
# LimitNOFILE=65536
#
sun.backup_compare '/etc/security/limits.conf'
sun.backup_compare '/etc/pam.d/sshd'
echo "session    required     pam_limits.so" >> /etc/pam.d/sshd
echo "*               soft    nproc           65536" >> /etc/security/limits.conf
echo "*               hard    nproc           65536" >> /etc/security/limits.conf
echo "*               soft    nofile          65536" >> /etc/security/limits.conf
echo "*               hard    nofile          65536" >> /etc/security/limits.conf
echo "fs.file-max = 524288" >> /etc/sysctl.conf
sysctl -p
ulimit -Sn 65536
