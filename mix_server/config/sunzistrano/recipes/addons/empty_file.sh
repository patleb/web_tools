empty_size=${empty_size:-2G}
fallocate -l ${empty_size} /opt/empty
chmod 770 /opt/empty
