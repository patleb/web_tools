# Model specific configuration object.
class RailsAdmin::Config::Model
  require_relative 'model/fields'
  require_relative 'model/sections'

  include RailsAdmin::Config::Proxyable
  include RailsAdmin::Config::Configurable
  include RailsAdmin::Config::Hideable

  attr_reader :i18n_key, :model_name, :abstract_model
  attr_accessor :groups

  delegate :klass, to: :abstract_model, allow_nil: true

  def initialize(model_name)
    @i18n_key = model_name.underscore
    @model_name = model_name
    @abstract_model = RailsAdmin::AbstractModel.all[model_name]
    @groups = [Fields::Group.new(base, :default).tap{ |g| g.label{ I18n.translate('admin.form.basic_info') } }]
  end

  def i18n_scope
    :adminrecord
  end

  def object_label
    label =
      object.send(object_label_method).presence \
      || (object.try("#{object_label_method}_was").presence if object.try("#{object_label_method}_changed?")) \
      || object.send(:rails_admin_object_label)
    label = "#{label} [#{I18n.t('admin.misc.discarded')}]" if object&.discarded?
    label
  end

  def pluralize(count)
    count == 1 ? label : label_plural
  end

  def weight
    "#{(navigation_weight + 32768).to_s}#{label.downcase}"
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
  # https://github.com/onomojo/i18n-timezones
  register_instance_option :time_zone, memoize: true do
    nil
  end

  # The display for a model instance (i.e. a single database record).
  # Unless configured in a model config block, it'll try to use :name followed by :title methods, then
  # any methods that may have been added to the label_methods array via Configuration.
  # Failing all of these, it'll return the class name followed by the model's id.
  register_instance_option :object_label_method, memoize: true do
    RailsAdmin.config.label_methods.find{ |method| klass.method_defined? method } || :rails_admin_object_label
  end

  register_instance_option :label, memoize: :locale do
    abstract_model.pretty_name
  end

  register_instance_option :label_plural, memoize: :locale do
    if label != (label_plural = abstract_model.pretty_name(count: Float::INFINITY, default: label))
      label_plural
    else
      label.pluralize(Current.locale)
    end
  end

  register_instance_option :navigation_weight, memoize: true do
    0
  end

  register_instance_option :navigation_parent, memoize: true do
    parent_class = klass.superclass
    if parent_class.respond_to? :extended_record_base_class
      parent_class.extended_record_base_class.to_s
    elsif parent_class.try(:abstract_class?) || parent_class.in?([Object, BasicObject])
      nil
    else
      parent_class.to_s
    end
  end

  register_instance_option :navigation_label, memoize: :locale do
    if navigation_label_i18n_key
      I18n.t(navigation_label_i18n_key, scope: [i18n_scope, :navigation_labels], default: I18n.t('admin.misc.navigation_label'))
    else
      I18n.t(i18n_key, scope: [i18n_scope, :navigation_labels], default:
        if (parent_module = klass.module_parent != Object)
          I18n.t(parent_module.name.underscore, scope: [i18n_scope, :navigation_labels], default: parent_module.name.humanize)
        else
          I18n.t('admin.misc.navigation_label')
        end
      )
    end
  end

  register_instance_option :navigation_label_i18n_key, memoize: true do
    nil
  end

  register_instance_option :navigation_icon, memoize: true do
    nil
  end

  register_instance_option :save_label?, memoize: :locale do
    I18n.t("#{i18n_key}.save", scope: [i18n_scope, :forms], default: I18n.t("admin.form.save"))
  end

  register_instance_option :save_and_add_another_label?, memoize: :locale do
    I18n.t("#{i18n_key}.save_and_add_another", scope: [i18n_scope, :forms], default: I18n.t("admin.form.save_and_add_another"))
  end

  register_instance_option :save_and_edit_label?, memoize: :locale do
    I18n.t("#{i18n_key}.save_and_edit", scope: [i18n_scope, :forms], default: I18n.t("admin.form.save_and_edit"))
  end

  register_instance_option :cancel_label?, memoize: :locale do
    I18n.t("#{i18n_key}.cancel", scope: [i18n_scope, :forms], default: I18n.t("admin.form.cancel"))
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
