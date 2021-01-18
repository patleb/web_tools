require 'dotiw'
require 'optparse'
require 'ext_ruby'
require 'mix_task/configuration'
require 'mix_task/engine' if defined? Rails

module ActiveTask
  autoload :Base, 'mix_task/active_task/base'
end

module MixTask
  module Pg
    autoload :Psql,      'tasks/mix_task/pg/psql'
    autoload :Rescuable, 'tasks/mix_task/pg/rescuable'
  end

  module Vpn
    autoload :Connect, 'tasks/mix_task/vpn/connect'
  end
end
