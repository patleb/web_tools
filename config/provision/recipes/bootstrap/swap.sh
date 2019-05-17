case "$OS" in
ubuntu)
  fallocate -l <%= @sun.swap_size %> /swap
  chmod 600 /swap
  mkswap /swap
  swapon /swap
  echo '/swap   none    swap    sw    0   0' >> /etc/fstab
;;
centos)
  dd if=/dev/zero of=/swap bs=1<%= @sun.swap_size[-1] %> count=<%= @sun.swap_size[0..-2] %>
  chmod 600 /swap
  mkswap /swap
  swapon /swap
  echo '/swap   swap    swap    defaults    0   0' >> /etc/fstab
;;
esac

echo 'vm.swappiness=10' >> /etc/sysctl.conf
echo 'vm.vfs_cache_pressure=50' >> /etc/sysctl.conf
