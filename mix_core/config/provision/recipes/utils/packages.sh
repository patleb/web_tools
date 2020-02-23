<% %W(
  arp-scan
  iftop
  iotop
  iptraf
  #{'iputils' if sun.os.centos?}
  #{'iputils-ping' if sun.os.ubuntu?}
  #{'iputils-tracepath' if sun.os.ubuntu?}
  jq
  nethogs
  ngrep
  nmap
  tree
).reject(&:blank?).each do |package| %>

  # https://github.com/blacksmoke16/oq
  sun.install "<%= package %>"

<% end %>
