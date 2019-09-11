require 'ext_capistrano/all'
require 'ext_sql/capistrano' if Gem.loaded_specs['ext_sql']
require 'ext_whenever/capistrano' if Gem.loaded_specs['ext_whenever']
require 'mr_backup/capistrano' if Gem.loaded_specs['mr_backup']
require 'mr_setting/capistrano' if Gem.loaded_specs['mr_setting']
require 'mr_backend/sh'
require_rel 'capistrano'
include MrBackend::Helpers

load 'tasks/mr_backend.cap'
