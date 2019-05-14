require 'ext_sql/capistrano' if Gem.loaded_specs['ext_sql']
require 'ext_whenever/capistrano' if Gem.loaded_specs['ext_whenever']
require 'mr_backup/capistrano' if Gem.loaded_specs['mr_backup']
require 'mr_secret/capistrano' if Gem.loaded_specs['mr_secret']
require_rel 'capistrano'
include MrSystem::Helpers

load 'tasks/mr_system.cap'
