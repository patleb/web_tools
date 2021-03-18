require 'ext_capistrano/all'
require 'ext_rails/capistrano'
require 'ext_whenever/capistrano' if Gem.loaded_specs['ext_whenever']
require 'mix_backup/capistrano' if Gem.loaded_specs['mix_backup']
require 'mix_job/capistrano'
require 'mix_setting/capistrano'
require 'mix_server/sh'
require 'mix_server/capistrano/helpers'
include MixServer::Helpers

load 'tasks/mix_server.cap'
