# Model specific configuration object.
class RailsAdmin::Config::Model
  require_relative 'model/fields'
  require_relative 'model/sections'

  include RailsAdmin::Config::Proxyable
  include RailsAdmin::Config::Configurable
  include RailsAdmin::Config::Hideable

  attr_reader :model_name, :abstract_model
  attr_accessor :groups

  delegate :klass, to: :abstract_model

  def initialize(model_name)
    @model_name = model_name
    @abstract_model = RailsAdmin::AbstractModel.all[model_name]
    @groups = [Fields::Group.new(base, :default).tap{ |g| g.label{ I18n.translate('admin.form.basic_info') } }]
  end

  def object_label
    label =
      object.send(object_label_method).presence \
      || (object.try("#{object_label_method}_was").presence if object.try("#{object_label_method}_changed?")) \
      || object.send(:rails_admin_default_object_label_method)
    label = "#{label} [REMOVED]" if object&.discarded?
    label
  end

  def navigation_weight
    "#{(weight + 32768).to_s}#{label.downcase}"
  end

  register_instance_option :visible? do
    !abstract_model.nil?
  end

  register_instance_option :discardable?, memoize: true do
    if (discard_column = klass.try(:discard_column))
      klass.column_names.include? discard_column.to_s
    end
  end

  # TODO show time zone in list view if specified
  register_instance_option :time_zone, memoize: true do
    nil
  end

  # The display for a model instance (i.e. a single database record).
  # Unless configured in a model config block, it'll try to use :name followed by :title methods, then
  # any methods that may have been added to the label_methods array via Configuration.
  # Failing all of these, it'll return the class name followed by the model's id.
  register_instance_option :object_label_method, memoize: true do
    RailsAdmin.config.label_methods.find{ |method| klass.method_defined? method } || :rails_admin_default_object_label_method
  end

  register_instance_option :label, memoize: :locale do
    abstract_model.pretty_name
  end

  register_instance_option :label_plural, memoize: :locale do
    abstract_model.pretty_name(count: Float::INFINITY, default: label.pluralize(Current.locale))
  end

  def pluralize(count)
    count == 1 ? label : label_plural
  end

  register_instance_option :weight, memoize: true do
    0
  end

  # parent node in navigation/breadcrumb
  register_instance_option :parent, memoize: true do
    parent_class = klass.superclass
    if parent_class.respond_to? :extended_record_base_class
      parent_class.extended_record_base_class.to_s
    else
      parent_class.to_s.in?(%w(Object BasicObject ActiveRecord::Base)) ? nil : parent_class.to_s
    end
  end

  register_instance_option :navigation_label, memoize: :locale do
    if (parent_module = klass.parent) != Object
      parent_module.name
    end
  end

  register_instance_option :navigation_icon, memoize: true do
    nil
  end

  register_instance_option :save_label, memoize: :locale do
    I18n.t("admin.form.save")
  end

  register_instance_option :save_and_add_another_label, memoize: :locale do
    I18n.t("admin.form.save_and_add_another")
  end

  register_instance_option :save_and_edit_label, memoize: :locale do
    I18n.t("admin.form.save_and_edit")
  end

  register_instance_option :cancel_label, memoize: :locale do
    I18n.t("admin.form.cancel")
  end

  # Act as a proxy for the base section configuration that actually
  # store the configurations.
  def method_missing(name, *args, &block)
    base.__send__(name, *args, &block)
  end

  def respond_to_missing?(name, _include_private = false)
    base.respond_to?(name, true)
  end
end
