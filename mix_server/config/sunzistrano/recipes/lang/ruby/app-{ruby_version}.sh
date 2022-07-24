sun.install "libjemalloc-dev"

sudo su - deployer << 'EOF'
  PLUGINS_PATH=/home/deployer/.rbenv/plugins
  PROFILE=/home/deployer/.bashrc
  RUBY_VERSION=<%= sun.ruby_version %>
  RBENV_OPTIONS='--with-jemalloc <%= '--enable-shared' if sun.ruby_cpp %> --disable-install-doc --disable-install-rdoc --disable-install-capi'

  if [[ ! -s "/home/deployer/.rbenv" ]]; then
    git clone https://github.com/sstephenson/rbenv.git /home/deployer/.rbenv
    git clone https://github.com/sstephenson/ruby-build.git $PLUGINS_PATH/ruby-build
    git clone https://github.com/sstephenson/rbenv-gem-rehash.git $PLUGINS_PATH/rbenv-gem-rehash
    git clone https://github.com/dcarley/rbenv-sudo.git $PLUGINS_PATH/rbenv-sudo

    echo '<%= Sh.rbenv_export %>' >> $PROFILE
    echo '<%= Sh.rbenv_init %>' >> $PROFILE
    echo 'gem: --no-document' > /home/deployer/.gemrc
  else
    cd /home/deployer/.rbenv && git remote set-url origin https://github.com/sstephenson/rbenv.git && git pull
    cd $PLUGINS_PATH/ruby-build && git remote set-url origin https://github.com/sstephenson/ruby-build.git && git pull
    cd $PLUGINS_PATH/rbenv-gem-rehash && git remote set-url origin https://github.com/sstephenson/rbenv-gem-rehash.git && git pull
    cd $PLUGINS_PATH/rbenv-sudo && git remote set-url origin https://github.com/dcarley/rbenv-sudo.git && git pull
    cd /home/deployer
  fi

  <%= Sh.rbenv_export %>
  <%= Sh.rbenv_init %>

  RUBY_CONFIGURE_OPTS=$RBENV_OPTIONS rbenv install $RUBY_VERSION
  rbenv global $RUBY_VERSION
EOF
