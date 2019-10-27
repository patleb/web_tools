require 'ext_capistrano/all'
require 'ext_sql/capistrano' if Gem.loaded_specs['ext_sql']
require 'ext_whenever/capistrano' if Gem.loaded_specs['ext_whenever']
require 'mr_setting/capistrano' if Gem.loaded_specs['mr_setting']
require 'mr_core/sh'
require_rel 'capistrano'
include MrCore::Helpers

load 'tasks/mr_core.cap'
