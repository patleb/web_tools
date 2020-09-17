module ActiveRecord::Base::WithDiscard
  extend ActiveSupport::Concern

  included do
    include Discard::Model

    self.discard_column = :deleted_at

    scope :only_discarded, -> { with_discarded.discarded }
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
