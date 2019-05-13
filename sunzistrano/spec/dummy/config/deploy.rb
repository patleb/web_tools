# config valid only for current version of Capistrano
lock '3.8.2'

set :application, 'chip_api'
set :repo_url, 'git@github.com:patleb/sunzistrano.git'

set :nginx_ssl_server, 'example.com'
append :nginx_denied_ips, '201.19.200.42', '185.169.230.8'
