### References
# https://github.com/jhawthorn/discard
module ActiveRecord::Base::WithDiscard
  extend ActiveSupport::Concern

  included do
    class_attribute :discard_column
    self.discard_column = :deleted_at

    scope :as_discardable,  ->(record) { record.discarded ? discarded : undiscarded }
    scope :all_discardable, -> { Current.discarded ? discarded : undiscarded }
    scope :undiscarded,     -> { discardable ? where(discard_column => nil) : all }
    scope :discarded,       -> { discardable ? with_discarded.where.not(discard_column => nil) : all }
    scope :with_discarded,  -> { discardable ? unscope(where: discard_column) : all }

    define_model_callbacks :discard
    define_model_callbacks :undiscard
  end

  class_methods do
    def inherited(subclass)
      super
      if subclass.name && !(subclass <= ActiveType::Object)
        if subclass.default_scopes.none?{ |o| o.scope.source_location.include?(__FILE__) }
          subclass.send(:default_scope){ discardable ? undiscarded : all }
        end
      end
    end

    def discardable
      return @_discardable && Current.discardable? if defined? @_discardable
      @_discardable = ExtRails.config.discardable? && column_names.include?(discard_column.to_s)
      discardable
    end
    alias_method :discardable?, :discardable

    def undiscardable
      !discardable
    end
    alias_method :undiscardable?, :undiscardable

    def discard_all
      all.each(&:discard)
    end

    def discard_all!
      all.each(&:discard!)
    end

    def undiscard_all
      discarded.each(&:undiscard)
    end

    def undiscard_all!
      discarded.each(&:undiscard!)
    end
  end

  def discarded
    self[discard_column].present?
  end
  alias_method :discarded?, :discarded

  def undiscarded
    !discarded
  end
  alias_method :undiscarded?, :undiscarded

  def discard
    return true if discarded?
    with_transaction_returning_status do
      run_callbacks(:discard) do
        update_attribute(discard_column, Time.current)
      end
    end
  end

  def discard!
    discard or raise ActiveRecord::ActiveRecordError, 'Failed to discard the record'
  end

  def undiscard
    return true unless discarded?
    with_transaction_returning_status do
      run_callbacks(:undiscard) do
        update_attribute(discard_column, nil)
      end
    end
  end

  def undiscard!
    undiscard or raise ActiveRecord::ActiveRecordError, "Failed to undiscard the record"
  end

  def discard_all(has_many, raise_on_error = false)
    discard_name = raise_on_error ? :discard_all! : :discard_all
    without_default_scope_on_association(has_many) do |association|
      association.public_send(discard_name)
    end
  end

  def discard_all!(has_many)
    discard_all(has_many, true)
  end

  def undiscard_all(has_many, raise_on_error = false)
    undiscard_name = raise_on_error ? :undiscard_all! : :undiscard_all
    without_default_scope_on_association(has_many) do |association, klass|
      if self.class.column_names.include?('updated_at') && klass.column_names.include?('updated_at')
        association = association.where(klass.column(:updated_at) >= updated_at - 1.second)
      end
      association.public_send(undiscard_name)
    end
  end

  def undiscard_all!(has_many)
    undiscard_all(has_many, true)
  end
end
