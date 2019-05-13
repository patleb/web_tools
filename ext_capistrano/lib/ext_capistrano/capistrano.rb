require 'sun_cap/capistrano' if Gem.loaded_specs['sun_cap']

require_rel 'capistrano/helpers'
include ExtCapistrano::FileHelper

load 'tasks/ext_capistrano.cap'
