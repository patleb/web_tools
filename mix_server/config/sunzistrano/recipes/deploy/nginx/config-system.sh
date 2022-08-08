desc 'Add /etc/nginx/nginx.conf'
nginx.copy_system_conf

desc "Add /etc/nginx/sites-available/${stage}"
nginx.compile_stage

desc 'Add public/503.html'
nginx.compile_503
