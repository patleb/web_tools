<% %W(
  iftop
  iotop
  jq
  nethogs
  nmap
  tree
  ncdu
).compact_blank.each do |package| %>
  sun.install "<%= package %>"
<% end %>
