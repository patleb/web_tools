module Admin
  module Fields
    class BelongsToListParent < BelongsTo
      def self.has?(section, property)
        return false unless (association = super)
        association.list_parent?
      end

      def allowed_field?
        action.sort? && super
      end

      def editable?
        false
      end
    end
  end
end
