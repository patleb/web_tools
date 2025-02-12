<% sun.denied_ips.each do |ip| %>
  <% if ip.start_with? '!' %>
    ufw delete deny from <%= ip[1..-1] %>
  <% else %>
    ufw deny from <%= ip %>
  <% end %>
<% end %>

ufw reload
