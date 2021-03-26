__EMPTY_SIZE__=${__EMPTY_SIZE__:-2G}
fallocate -l $__EMPTY_SIZE__ /opt/empty
chmod 770 /opt/empty
