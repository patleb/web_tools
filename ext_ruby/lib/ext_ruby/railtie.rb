module ExtRuby
  class Railtie < Rails::Railtie
    config.before_configuration do
      require 'ext_ruby/rails/application'
    end
  end
end
