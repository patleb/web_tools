SWAP_NAME=/swap

if [[ $(swapon -s | grep $SWAP_NAME | awk '{ print $1; }') ]]; then
  swapoff -v $SWAP_NAME
  <%= Sh.delete_line! '/etc/fstab', '$SWAP_NAME' %>
  rm -f $SWAP_NAME
fi

case "$OS" in
ubuntu)
  fallocate -l $__SWAP_SIZE__ $SWAP_NAME
  chmod 600 $SWAP_NAME
  mkswap $SWAP_NAME
  swapon $SWAP_NAME
  echo "$SWAP_NAME   none    swap    sw    0   0" >> /etc/fstab
;;
centos)
  dd if=/dev/zero of=$SWAP_NAME bs=1<%= @sun.swap_size[-1] %> count=<%= @sun.swap_size[0..-2] %>
  chmod 600 $SWAP_NAME
  mkswap $SWAP_NAME
  swapon $SWAP_NAME
  echo "$SWAP_NAME   swap    swap    defaults    0   0" >> /etc/fstab
;;
esac

<%= Sh.concat('/etc/sysctl.conf', 'vm.swappiness=10', unique: true) %>
<%= Sh.concat('/etc/sysctl.conf', 'vm.vfs_cache_pressure=50', unique: true) %>
