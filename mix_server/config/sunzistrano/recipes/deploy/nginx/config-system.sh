site_available="/etc/nginx/sites-available/${stage}"
site_enabled="/etc/nginx/sites-enabled/${stage}"

desc 'Add /etc/nginx/nginx.conf'
sun.copy '/etc/nginx/nginx.conf' 0644 root:root

desc "Add $site_available"
sun.copy $site_available 0644 root:root

if [[ ! -h $site_enabled ]]; then
  desc 'Enable application'
  sudo ln -nfs $site_available $site_enabled
fi

desc 'Add public/503.html'
sun.copy "$shared_path/$(sun.flatten_path public/503.html)"
