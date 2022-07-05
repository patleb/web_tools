sun.install "libjemalloc-dev"

sudo su - $__DEPLOYER_NAME__ << 'EOF'
  DEPLOYER_NAME=<%= sun.deployer_name %>
  PLUGINS_PATH=/home/$DEPLOYER_NAME/.rbenv/plugins
  PROFILE=/home/$DEPLOYER_NAME/.bashrc
  RUBY_VERSION=<%= sun.rbenv_ruby %>
  RBENV_OPTIONS='--with-jemalloc <%= '--enable-shared' if sun.ruby_cpp %> --disable-install-doc --disable-install-rdoc --disable-install-capi'

  if [[ ! -s "/home/$DEPLOYER_NAME/.rbenv" ]]; then
    git clone https://github.com/sstephenson/rbenv.git /home/$DEPLOYER_NAME/.rbenv
    git clone https://github.com/sstephenson/ruby-build.git $PLUGINS_PATH/ruby-build
    git clone https://github.com/sstephenson/rbenv-gem-rehash.git $PLUGINS_PATH/rbenv-gem-rehash
    git clone https://github.com/dcarley/rbenv-sudo.git $PLUGINS_PATH/rbenv-sudo

    echo '<%= Sh.rbenv_export(sun.deployer_name) %>' >> $PROFILE
    echo '<%= Sh.rbenv_init %>' >> $PROFILE
    echo 'gem: --no-document' > /home/$DEPLOYER_NAME/.gemrc
  else
    cd /home/$DEPLOYER_NAME/.rbenv && git remote set-url origin https://github.com/sstephenson/rbenv.git && git pull
    cd $PLUGINS_PATH/ruby-build && git remote set-url origin https://github.com/sstephenson/ruby-build.git && git pull
    cd $PLUGINS_PATH/rbenv-gem-rehash && git remote set-url origin https://github.com/sstephenson/rbenv-gem-rehash.git && git pull
    cd $PLUGINS_PATH/rbenv-sudo && git remote set-url origin https://github.com/dcarley/rbenv-sudo.git && git pull
    cd /home/$DEPLOYER_NAME
  fi

  <%= Sh.rbenv_export(sun.deployer_name) %>
  <%= Sh.rbenv_init %>

  RUBY_CONFIGURE_OPTS=$RBENV_OPTIONS rbenv install $RUBY_VERSION
  rbenv global $RUBY_VERSION
EOF
