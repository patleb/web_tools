# TODO https://ubuntu.com/tutorials/setup-zfs-storage-pool#1-overview
if fdisk -l | grep -Fq ${data_partition}; then
  if df -h | grep -Fq ${data_partition}; then
    : # do nothing --> already mounted
  else
    mkfs.ext4 ${data_partition}
    rm -rf ${data_directory}
    mkdir -p ${data_directory}
    mount ${data_partition} ${data_directory}
    echo "${data_partition}    ${data_directory}    auto    defaults,nofail    0    2" >> /etc/fstab
  fi
fi
