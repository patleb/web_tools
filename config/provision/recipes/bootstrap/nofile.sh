# TODO fs.file-max = 1000000
# TODO vm.max_map_count = 2500000
# /etc/systemd/system/nginx.service.d/nofile.conf
#
# [Service]
# LimitNOFILE=65536
#
# for i in 1 2 3 4 5; do ulimit -Sn 65536 && break || sleep 1; done --> will be applied on next login session
sun.backup_compare '/etc/pam.d/sshd'
sun.backup_compare '/etc/security/limits.conf'
echo "session    required     pam_limits.so" >> /etc/pam.d/sshd
echo "*               soft    nproc           65536" >> /etc/security/limits.conf
echo "*               hard    nproc           65536" >> /etc/security/limits.conf
echo "*               soft    nofile          65536" >> /etc/security/limits.conf
echo "*               hard    nofile          65536" >> /etc/security/limits.conf
echo "fs.file-max = 524288" >> /etc/sysctl.conf
sysctl -p
