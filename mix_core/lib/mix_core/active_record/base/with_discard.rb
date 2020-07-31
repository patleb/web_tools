module ActiveRecord::Base::WithDiscard
  extend ActiveSupport::Concern

  included do
    include Discard::Model

    self.discard_column = :deleted_at

    scope :discarded!, -> { with_discarded.discarded }
  end

  class_methods do
    def inherited(subclass)
      super
      if subclass.name && !(subclass <= ActiveType::Object)
        if subclass.default_scopes.none?{ |scope| scope.source_location.include?(__FILE__) }
          discard_scope = -> do
            if MixCore.config.skip_discard? && column_names.include?(try(:discard_column).to_s)
              kept
            else
              all
            end
          end
          subclass.send(:default_scope, discard_scope)
        end
      end
    end

    def undiscard_all
      discarded!.each(&:undiscard)
    end

    def undiscard_all!
      discarded!.each(&:undiscard!)
    end
  end
end
