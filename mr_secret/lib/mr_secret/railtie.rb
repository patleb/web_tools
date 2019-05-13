class MrSecret::Railtie < Rails::Railtie
  config.before_configuration do
    require 'mr_secret/rails/application'
  end

  rake_tasks do
    load 'tasks/mr_secret.rake'
  end
end
