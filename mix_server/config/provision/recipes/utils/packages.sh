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
).reject(&:blank?).each do |package| %>

  # https://github.com/blacksmoke16/oq
  sun.install "<%= package %>"

<% end %>
