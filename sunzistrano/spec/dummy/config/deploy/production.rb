set :stage, :production
set :server, 'admin.example.com'

server fetch(:server), user: fetch(:deployer_name), roles: %w[app web db]
