require 'sunzistrano/capistrano'

require_rel 'capistrano'
include ExtCapistrano::Helpers

load 'tasks/ext_capistrano.cap'
