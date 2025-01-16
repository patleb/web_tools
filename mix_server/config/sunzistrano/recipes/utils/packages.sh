<% %W(
  arp-scan
  iftop
  iotop
  iptraf
  iputils-ping
  iputils-tracepath
  jq
  nethogs
  ngrep
  nmap
  tree
  ncdu
).compact_blank.each do |package| %>
  sun.install "<%= package %>"
<% end %>
