__DATA_PARTITION__=${__DATA_PARTITION__:-/dev/vdc}
__DATA_DIRECTORY__=${__DATA_DIRECTORY__:-/opt/storage}
__DATA_ORDER__=${__DATA_ORDER__:-3}
if fdisk -l | grep -Fq $__DATA_PARTITION__; then
  if df -h | grep -Fq $__DATA_PARTITION__; then
    : # do nothing --> already mounted
  else
    mkfs.ext4 $__DATA_PARTITION__
    mkdir $__DATA_DIRECTORY__
    mount $__DATA_PARTITION__ $__DATA_DIRECTORY__
    echo "$__DATA_PARTITION__    $__DATA_DIRECTORY__    auto    defaults,nofail    0    $__DATA_ORDER__" >> /etc/fstab
  fi
fi
