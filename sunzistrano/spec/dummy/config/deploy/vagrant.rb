set :stage, :vagrant
set :branch, 'develop'
set :server, 'admin.example.dev'
set :owner_name, 'vagrant'
set :nginx_ssl_server, fetch(:server)

server fetch(:server), user: fetch(:deployer_name), roles: %w[app web db]
