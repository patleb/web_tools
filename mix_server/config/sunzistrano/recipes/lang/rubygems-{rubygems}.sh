gem update --system

sudo su - ${deployer_name} << 'EOF'
  set -eu
  RUBY_VERSION=<%= sun.ruby_version %>

  <%= Sh.rbenv_ruby %>

  declare -a ruby_versions=$(rbenv versions | cut -d ' ' -f 2-3 | sed -r 's/([ \(]|set|system)//g' | sed '/^\s*$/d')
  for version in $ruby_versions; do
    rbenv global $version
    gem update --system
  done
  rbenv global $RUBY_VERSION
EOF
