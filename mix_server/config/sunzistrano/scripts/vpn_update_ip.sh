# TODO
# could actually be replaced by a plain ruby file started with: "ruby path_to_file.rb" --> takes less than 10MB of RAM when env isn't loaded
# then run "exec 'RAILS_ENV=... bin/rake ...'" to replace current process when necessary
PREVIOUS_IP=$(cat "$shared_path/vpn_ip" || :)
CURRENT_IP=$(sun.public_ip)

if [[ "$CURRENT_IP" != "$PREVIOUS_IP" ]]; then
  bin/rake vpn:update_ip -- --ip=$CURRENT_IP
fi
