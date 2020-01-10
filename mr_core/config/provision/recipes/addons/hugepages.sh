THIRD_OF_MEM=$(grep MemTotal /proc/meminfo | awk '{print int($2 / 1024 / 3)}') # MB
HUGEPAGES_MAX=$((THIRD_OF_MEM / 2)) # 2MB
MEMLOCK_MAX=$((THIRD_OF_MEM * 1024)) # KB

sun.install "libhugetlbfs"

case "$OS" in
ubuntu)
  :
;;
centos)
  sun.install "libhugetlbfs-utils"
;;
esac

echo "vm.nr_hugepages = $HUGEPAGES_MAX" >> /etc/sysctl.conf
echo "*               soft    memlock           $MEMLOCK_MAX" >> /etc/security/limits.conf
echo "*               hard    memlock           $MEMLOCK_MAX" >> /etc/security/limits.conf
sysctl -p
