if ENV['CLUSTER']
  require 'capistrano/bundle_rsync/plugin'
  install_plugin Capistrano::BundleRsync::Plugin
else
  require "capistrano/scm/git"
  install_plugin Capistrano::SCM::Git
end
