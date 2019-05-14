# https://www.digitalocean.com/community/questions/how-to-change-swap-size-on-ubuntu-14-04
# https://www.digitalocean.com/community/tutorials/how-to-add-swap-on-ubuntu-14-04
# dd if=/dev/zero of=/swap bs=1M count=1024

fallocate -l <%= @sun.swap_size || '1024M' %> /swap
chmod 600 /swap
mkswap /swap
swapon /swap

echo '/swap   none    swap    sw    0   0' >> /etc/fstab
echo 'vm.swappiness=10' >> /etc/sysctl.conf
echo 'vm.vfs_cache_pressure=50' >> /etc/sysctl.conf
