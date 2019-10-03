if Gem.loaded_specs['sun_cap'] && Setting[:server_cluster_provider]
  require 'capistrano/bundle_rsync/plugin'
  install_plugin Capistrano::BundleRsync::Plugin
else
  require "capistrano/scm/git"
  install_plugin Capistrano::SCM::Git
end
