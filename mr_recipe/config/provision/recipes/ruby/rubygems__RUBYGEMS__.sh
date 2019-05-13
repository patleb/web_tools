DEPLOYER_NAME=<%= @sun.deployer_name %>

gem update --system

sudo su - $DEPLOYER_NAME << 'EOF'
  RUBY_VERSION=<%= @sun.rbenv_ruby %>

  <%= Sh.rbenv_export(@sun.deployer_name) %>
  <%= Sh.rbenv_init %>

  declare -a ruby_versions=$(rbenv versions | cut -d ' ' -f 2-3 | sed -r 's/([ \(]|set|system)//g' | sed '/^\s*$/d')
  for version in $ruby_versions; do
    rbenv global $version
    gem update --system
  done
  rbenv global $RUBY_VERSION
EOF
