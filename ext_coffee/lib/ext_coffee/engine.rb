require 'ext_ruby'
require 'ext_coffee/configuration'

module ExtCoffee
  class Engine < ::Rails::Engine
    require 'turbolinks'
  end
end
