<% %W(
  iftop
  iotop
  nethogs
  nmap
  tree
  ncdu
).compact_blank.each do |package| %>
  sun.install "<%= package %>"
<% end %>
