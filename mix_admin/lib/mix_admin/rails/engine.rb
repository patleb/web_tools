Rails::Engine.class_eval do
  def autoload_models_if_admin(models, engine = self)
    unless defined? MixAdmin
      Array.wrap(models).each do |model|
        Rails.autoloaders.main.ignore("#{engine.root}/app/models/#{model.to_s.underscore}_admin.rb")
      end
    end
  end
end
