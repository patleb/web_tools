<% %W(
  arp-scan
  iftop
  iotop
  nethogs
  net-tools
  nmap
  tree
  ncdu
).compact_blank.each do |package| %>
  sun.install "<%= package %>"
<% end %>
