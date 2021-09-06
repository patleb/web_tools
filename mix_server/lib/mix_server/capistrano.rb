require 'ext_capistrano/all'
require 'ext_rails/capistrano'
require 'ext_whenever/capistrano'
require 'mix_geo/capistrano' if Gem.loaded_specs['mix_geo']
require 'mix_job/capistrano' if Gem.loaded_specs['mix_job']
require 'mix_file/capistrano' if Gem.loaded_specs['mix_file']
require 'mix_setting/capistrano'
require 'mix_server/sh'
require 'mix_server/capistrano/helpers'
include MixServer::Helpers

load 'tasks/mix_server.cap'
