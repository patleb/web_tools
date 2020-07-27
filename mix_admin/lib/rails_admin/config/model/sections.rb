# Sections describe different views in the RailsAdmin engine.
#
# Each section's class object can store generic configuration about that section (such as the
# number of visible tabs in the main navigation), while the instances (accessed via model
# configuration objects) store model specific configuration (such as the visibility of the
# model).
module RailsAdmin::Config::Model::Sections
  require_rel 'sections'

  constants.each do |name|
    section = const_get(name)
    name = name.to_s.underscore.to_sym
    RailsAdmin::Config::Model.define_method name do |&block|
      @sections = {} unless @sections
      @sections[name] = section.new(self) unless @sections[name]
      @sections[name].instance_eval(&block) if block
      @sections[name]
    end
  end
end
