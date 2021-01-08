module ActiveRecord::Base::WithUser
  extend ActiveSupport::Concern

  included do
    class_attribute :record_userstamps, default: true

    self.skip_locking_attributes += ['updater_id']
  end

  def initialize_dup(other)
    super
    clear_userstamp_attributes
  end

  class_methods do
    def has_userstamp
      belongs_to :creator, class_name: 'User', optional: true
      belongs_to :updater, class_name: 'User', optional: true
    end

    def userstamp_attributes_for_create_in_model
      @userstamp_attributes_for_create_in_model ||= (userstamp_attributes_for_create & column_names).freeze
    end

    def userstamp_attributes_for_update_in_model
      @userstamp_attributes_for_update_in_model ||= (userstamp_attributes_for_update & column_names).freeze
    end

    def all_userstamp_attributes_in_model
      @all_userstamp_attributes_in_model ||= (
        userstamp_attributes_for_create_in_model + userstamp_attributes_for_update_in_model
      ).freeze
    end

    def current_user
      Current.user
    end

    private

    def userstamp_attributes_for_create
      ["creator_id"]
    end

    def userstamp_attributes_for_update
      ["updater_id"]
    end

    def reload_schema_from_cache
      @userstamp_attributes_for_create_in_model = nil
      @userstamp_attributes_for_update_in_model = nil
      @all_userstamp_attributes_in_model = nil
      super
    end
  end

  private

  def _create_record
    if record_userstamps
      current_user_id = current_user&.id

      all_userstamp_attributes_in_model.each do |column|
        unless attribute_present?(column)
          write_attribute(column, current_user_id)
        end
      end
    end

    super
  end

  def _update_record
    if @_touch_record && should_record_userstamps?
      current_user_id = current_user&.id

      userstamp_attributes_for_update_in_model.each do |column|
        next if will_save_change_to_attribute?(column)
        write_attribute(column, current_user_id)
      end
    end

    super
  end

  def should_record_userstamps?
    record_userstamps && (!partial_writes? || has_changes_to_save?)
  end

  def userstamp_attributes_for_create_in_model
    self.class.userstamp_attributes_for_create_in_model
  end

  def userstamp_attributes_for_update_in_model
    self.class.userstamp_attributes_for_update_in_model
  end

  def all_userstamp_attributes_in_model
    self.class.all_userstamp_attributes_in_model
  end

  def current_user
    self.class.current_user
  end

  # Clear attributes and changed_attributes
  def clear_userstamp_attributes
    all_userstamp_attributes_in_model.each do |attribute_name|
      self[attribute_name] = nil
      clear_attribute_changes([attribute_name])
    end
  end
end
