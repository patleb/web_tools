require 'ext_capistrano/all'
require 'ext_whenever/capistrano' if Gem.loaded_specs['ext_whenever']
require 'mix_backup/capistrano' if Gem.loaded_specs['mix_backup']
require 'mix_setting/capistrano'
require 'mix_sql/capistrano' if Gem.loaded_specs['mix_sql']
require 'ext_rails/sh'
require_rel 'capistrano'
include ExtRails::Helpers

load 'tasks/ext_rails.cap'
