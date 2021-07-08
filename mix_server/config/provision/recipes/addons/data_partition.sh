# TODO https://ubuntu.com/tutorials/setup-zfs-storage-pool#1-overview
__DATA_PARTITION__=${__DATA_PARTITION__:-/dev/vdc}
__DATA_ORDER__=${__DATA_ORDER__:-3}
if fdisk -l | grep -Fq $__DATA_PARTITION__; then
  if df -h | grep -Fq $__DATA_PARTITION__; then
    : # do nothing --> already mounted
  else
    mkfs.ext4 $__DATA_PARTITION__
    rm -rf $__DATA_DIRECTORY__
    mkdir -p $__DATA_DIRECTORY__
    mount $__DATA_PARTITION__ $__DATA_DIRECTORY__
    echo "$__DATA_PARTITION__    $__DATA_DIRECTORY__    auto    defaults,nofail    0    $__DATA_ORDER__" >> /etc/fstab
  fi
fi
