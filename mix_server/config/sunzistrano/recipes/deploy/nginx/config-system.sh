desc 'Add /etc/nginx/nginx.conf'
sun.copy '/etc/nginx/nginx.conf' 0644 root:root

desc "Add /etc/nginx/sites-available/${stage}"
nginx.compile_stage

desc 'Add public/503.html'
nginx.compile_503
