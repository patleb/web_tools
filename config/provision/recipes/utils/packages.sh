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

  sun.install "<%= package %>"

<% end %>
