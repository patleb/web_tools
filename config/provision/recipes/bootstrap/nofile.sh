# https://github.com/serverless/serverless/issues/3249

ulimit -Sn 65536
echo "session required pam_limits.so" >> /etc/pam.d/common-session
echo "root soft  nofile 40000" >> /etc/security/limits.conf
echo "root hard  nofile 100000" >> /etc/security/limits.conf
