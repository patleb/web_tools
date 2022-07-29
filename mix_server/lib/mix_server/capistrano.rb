require 'ext_capistrano/all'
require 'ext_rails/capistrano'
require 'mix_geo/capistrano' if Gem.loaded_specs['mix_geo']
require 'mix_file/capistrano' if Gem.loaded_specs['mix_file']
require 'mix_server/sh'

load 'tasks/mix_server.cap'
