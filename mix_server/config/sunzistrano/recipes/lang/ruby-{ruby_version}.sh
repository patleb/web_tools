sudo su - deployer << 'EOF'
  set -eu
  PLUGINS_PATH=/home/deployer/.rbenv/plugins
  PROFILE=/home/deployer/.bashrc
  RUBY_VERSION=<%= sun.ruby_version %>

  if [[ ! -s "/home/deployer/.rbenv" ]]; then
    git clone https://github.com/sstephenson/rbenv.git /home/deployer/.rbenv --depth=1
    git clone https://github.com/sstephenson/ruby-build.git $PLUGINS_PATH/ruby-build --depth=1
    git clone https://github.com/dcarley/rbenv-sudo.git $PLUGINS_PATH/rbenv-sudo --depth=1

    echo '<%= Sh.rbenv_ruby %>' >> $PROFILE
    echo 'gem: --no-document' > /home/deployer/.gemrc
  else
    cd /home/deployer/.rbenv && git remote set-url origin https://github.com/sstephenson/rbenv.git && git pull
    cd $PLUGINS_PATH/ruby-build && git remote set-url origin https://github.com/sstephenson/ruby-build.git && git pull
    cd $PLUGINS_PATH/rbenv-sudo && git remote set-url origin https://github.com/dcarley/rbenv-sudo.git && git pull
    cd /home/deployer
  fi

  <%= Sh.rbenv_ruby %>

  RUBY_CONFIGURE_OPTS='--enable-yjit --with-jemalloc --disable-install-doc' rbenv install $RUBY_VERSION
  rbenv global $RUBY_VERSION
  ruby --version --yjit
EOF
