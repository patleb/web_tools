require 'ext_capistrano/all'
require 'ext_sql/capistrano' if Gem.loaded_specs['ext_sql']
require 'ext_whenever/capistrano' if Gem.loaded_specs['ext_whenever']
require 'mix_backup/capistrano' if Gem.loaded_specs['mix_backup']
require 'mix_setting/capistrano' if Gem.loaded_specs['mix_setting']
require 'mix_core/sh'
require_rel 'capistrano'
include MixCore::Helpers

load 'tasks/mix_core.cap'
