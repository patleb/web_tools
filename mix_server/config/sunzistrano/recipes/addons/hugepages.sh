THIRD_OF_MEM=$(grep MemTotal /proc/meminfo | awk '{print int($2 / 1024 / 3)}') # MB
HUGEPAGES_MAX=$((THIRD_OF_MEM / 2)) # 2MB
MEMLOCK_MAX=$((THIRD_OF_MEM * 1024)) # KB

sun.install "libhugetlbfs"

echo "vm.nr_hugepages = $HUGEPAGES_MAX" >> /etc/sysctl.conf
echo "*               soft    memlock           $MEMLOCK_MAX" >> /etc/security/limits.conf
echo "*               hard    memlock           $MEMLOCK_MAX" >> /etc/security/limits.conf
sysctl -p

<% if sun.disable_thp %>
  sun.copy '/etc/systemd/system/disable_thp.service'
  sun.service_enable disable_thp
<% end %>
