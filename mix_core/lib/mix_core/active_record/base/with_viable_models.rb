module ActiveRecord::Base::WithViableModels
  extend ActiveSupport::Concern

  EXCLUDED_MODEL_SUFFIXES = IceNine.deep_freeze(%w(
    .include.rb
    .prepend.rb
    _admin.rb
    _record.rb
    _decorator.rb
    /current.rb
    /root.rb
    /null.rb
    /base.rb
  ))

  class_methods do
    def viable_models
      @viable_models ||= begin
        included_models = ([Rails.application] + Rails::Engine.subclasses).map do |app|
          paths = app.config.paths['app/models'].to_a + app.config.paths.eager_load.select(&:end_with?.with('/models'))
          paths.uniq.map do |load_path|
            Dir.glob(app.root.join(load_path)).map do |load_dir|
              Dir.glob(load_dir + '/**/*.rb').map do |filename|
                unless filename.include?('/concerns/') || filename.end_with?(*EXCLUDED_MODEL_SUFFIXES)
                  filename.delete_prefix("#{app.root.join(load_dir)}/").delete_suffix('.rb').camelize
                end
              end.compact
            end
          end
        end.flatten
        included_models.reject do |model|
          MixCore.config.excluded_models.include? model
        end
      end
    end
  end
end
