MonkeyPatch.add{['activerecord', 'lib/active_record/timestamp.rb', '39c0b41b72a1d5dd7fec683f91d06ac434328846c05187c412b47b782969d4da']}

module ActiveRecord::Base::WithUser
  extend ActiveSupport::Concern

  included do
    class_attribute :record_userstamps, default: true

    self.skip_locking_attributes += ['updater_id']
  end

  def initialize_dup(other)
    super
    clear_userstamps_attributes
  end

  class_methods do
    def has_userstamps
      belongs_to :creator, class_name: 'User', optional: true
      belongs_to :updater, class_name: 'User', optional: true
    end

    def userstamps_attributes_for_create_in_model
      @userstamps_attributes_for_create_in_model ||= (userstamps_attributes_for_create & column_names).freeze
    end

    def userstamps_attributes_for_update_in_model
      @userstamps_attributes_for_update_in_model ||= (userstamps_attributes_for_update & column_names).freeze
    end

    def all_userstamps_attributes_in_model
      @all_userstamps_attributes_in_model ||= (
        userstamps_attributes_for_create_in_model + userstamps_attributes_for_update_in_model
      ).freeze
    end

    def current_user
      Current.user if Current.logged_in?
    end

    protected

    def reload_schema_from_cache(recursive = true)
      @userstamps_attributes_for_create_in_model = nil
      @userstamps_attributes_for_update_in_model = nil
      @all_userstamps_attributes_in_model = nil
      super
    end

    private

    def userstamps_attributes_for_create
      ["creator_id"].map!{ |name| attribute_aliases[name] || name }
    end

    def userstamps_attributes_for_update
      ["updater_id"].map!{ |name| attribute_aliases[name] || name }
    end
  end

  private

  def _create_record
    if record_userstamps
      current_user_id = current_user&.id

      all_userstamps_attributes_in_model.each do |column|
        _write_attribute(column, current_user_id) unless _read_attribute(column)
      end
    end

    super
  end

  def _update_record
    record_update_userstamps
    super
  end

  def record_update_userstamps
    if @_touch_record && should_record_userstamps?
      current_user_id = current_user&.id

      userstamps_attributes_for_update_in_model.each do |column|
        next if will_save_change_to_attribute?(column)
        _write_attribute(column, current_user_id)
      end
    end
    yield if block_given?
  end

  def should_record_userstamps?
    record_userstamps && (!partial_updates? || has_changes_to_save?)
  end

  def userstamps_attributes_for_create_in_model
    self.class.userstamps_attributes_for_create_in_model
  end

  def userstamps_attributes_for_update_in_model
    self.class.userstamps_attributes_for_update_in_model
  end

  def all_userstamps_attributes_in_model
    self.class.all_userstamps_attributes_in_model
  end

  def current_user
    self.class.current_user
  end

  # Clear attributes and changed_attributes
  def clear_userstamps_attributes
    all_userstamps_attributes_in_model.each do |attribute_name|
      self[attribute_name] = nil
      clear_attribute_change(attribute_name)
    end
  end
end
