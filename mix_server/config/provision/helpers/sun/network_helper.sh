sun.network() {
  local addr=$(sun.ip_to_int $1)
  local mask=$((0xffffffff << (32 -$2)))
  sun.int_to_ip $((addr & mask))
}

sun.broadcast() {
  local addr=$(sun.ip_to_int $1)
  local mask=$((0xffffffff << (32 -$2)))
  sun.int_to_ip $((addr | ~mask))
}

sun.netmask() {
  local mask=$((0xffffffff << (32 - $1)))
  sun.int_to_ip $mask
}

sun.ip_to_int() {
  local ip="$1"
  local sum=0
  for (( i=0 ; i<4 ; ++i )); do
    ((sum+=${ip%%.*}*$((256**$((3-${i}))))))
    ip=${ip#*.}
  done
  echo $sum
}

sun.int_to_ip() {
  echo -n $(($(($(($((${1}/256))/256))/256))%256)).
  echo -n $(($(($((${1}/256))/256))%256)).
  echo -n $(($((${1}/256))%256)).
  echo $((${1}%256))
}

sun.default_interface() {
  <%= Sh.default_interface %>
}

sun.public_ip() {
  <%= Sh.public_ip %>
}

sun.private_ip() {
  <%= Sh.private_ip %>
}
