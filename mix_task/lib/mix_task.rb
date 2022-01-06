require 'dotiw'
require 'optparse'
require 'ext_ruby'
require 'mix_task/configuration'
require 'mix_task/engine' if defined? Rails

module ActiveTask
  autoload :Base, 'mix_task/active_task/base'
end

module ParallelTask
  autoload :Base, 'mix_task/parallel_task/base'
end
