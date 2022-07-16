__SWAP_SIZE__=${__SWAP_SIZE__:-1024M}
SWAP_NAME=/swap

if [[ $(swapon -s | grep $SWAP_NAME | awk '{ print $1; }') == "$SWAP_NAME" ]]; then
  swapoff -v $SWAP_NAME
  <%= Sh.delete_line! '/etc/fstab', "$SWAP_NAME", escape: false %>
  rm -f $SWAP_NAME
fi

if [[ ${__SWAP_SIZE__::1} != '0' ]] && [[ $__SWAP_SIZE__ != false ]]; then
  fallocate -l $__SWAP_SIZE__ $SWAP_NAME
  chmod 600 $SWAP_NAME
  mkswap $SWAP_NAME
  swapon -p 0 $SWAP_NAME
  echo "$SWAP_NAME   none    swap    sw,pri=0    0   0" >> /etc/fstab
fi

<%= Sh.concat('/etc/sysctl.conf', 'vm.swappiness=10', unique: true) %>
<%= Sh.concat('/etc/sysctl.conf', 'vm.vfs_cache_pressure=50', unique: true) %>
