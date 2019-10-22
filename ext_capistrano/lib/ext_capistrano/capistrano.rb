require 'sun_cap/capistrano' if Gem.loaded_specs['sun_cap']

require_rel 'capistrano'
include ExtCapistrano::Helpers

load 'tasks/ext_capistrano.cap'
