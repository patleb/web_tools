module ActiveRecord::Base::WithDiscard
  extend ActiveSupport::Concern

  included do
    include Discard::Model

    self.discard_column = :deleted_at

    scope :only_discarded, -> { with_discarded.discarded }

    alias_method :show?, :kept?
  end

  def discard_all(has_many, raise_on_error = false)
    discard_name = raise_on_error ? :discard_all! : :discard_all
    without_default_scope_on_association(has_many) do |association|
      association.send(discard_name)
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
      association.send(undiscard_name)
    end
  end

  def undiscard_all!(has_many)
    undiscard_all(has_many, true)
  end

  class_methods do
    def inherited(subclass)
      super
      if subclass.name && !(subclass <= ActiveType::Object)
        if subclass.default_scopes.none?{ |scope| scope.source_location.include?(__FILE__) }
          subclass.send(:default_scope) { with_discard ? kept : all }
        end
      end
    end

    def with_discard
      return @_with_discard if defined? @_with_discard
      @_with_discard = (!ExtRails.config.skip_discard? && column_names.include?(try(:discard_column).to_s)).to_b
    end
    alias_method :with_discard?, :with_discard

    def discard_all
      all.each(&:discard)
    end

    def discard_all!
      all.each(&:discard!)
    end

    def undiscard_all
      only_discarded.each(&:undiscard)
    end

    def undiscard_all!
      only_discarded.each(&:undiscard!)
    end
  end
end
