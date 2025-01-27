sudo su - ${deployer_name} << 'EOF'
  set -eu
  PLUGINS_PATH=/home/<%= sun.deployer_name %>/.rbenv/plugins
  PROFILE=/home/<%= sun.deployer_name %>/.bashrc
  RUBY_VERSION=<%= sun.ruby_version %>

  if [[ ! -s "/home/<%= sun.deployer_name %>/.rbenv" ]]; then
    git clone https://github.com/sstephenson/rbenv.git /home/<%= sun.deployer_name %>/.rbenv --depth=1
    git clone https://github.com/sstephenson/ruby-build.git $PLUGINS_PATH/ruby-build --depth=1
    git clone https://github.com/dcarley/rbenv-sudo.git $PLUGINS_PATH/rbenv-sudo --depth=1

    echo '<%= Sh.rbenv_ruby %>' >> $PROFILE
    echo 'gem: --no-document' > /home/<%= sun.deployer_name %>/.gemrc
  else
    cd /home/<%= sun.deployer_name %>/.rbenv && git remote set-url origin https://github.com/sstephenson/rbenv.git && git pull
    cd $PLUGINS_PATH/ruby-build && git remote set-url origin https://github.com/sstephenson/ruby-build.git && git pull
    cd $PLUGINS_PATH/rbenv-sudo && git remote set-url origin https://github.com/dcarley/rbenv-sudo.git && git pull
    cd /home/<%= sun.deployer_name %>
  fi

  <%= Sh.rbenv_ruby %>

  RUBY_CONFIGURE_OPTS='--enable-yjit --with-jemalloc --disable-install-doc' rbenv install $RUBY_VERSION
  rbenv global $RUBY_VERSION
  ruby --version --yjit
EOF
