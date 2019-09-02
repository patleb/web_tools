<% %W(
  arp-scan
  htop
  iftop
  iotop
  iptraf
  iputils
  jq
  nethogs
  ngrep
  nmap
  tree
).each do |package| %>

  # https://github.com/blacksmoke16/oq
  sun.install "<%= package %>"

<% end %>
