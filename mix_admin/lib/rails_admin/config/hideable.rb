module RailsAdmin
  module Config
    # Defines a visibility configuration
    module Hideable
      # Reader whether object is hidden.
      def hidden?
        !visible?
      end

      # Writer to hide object.
      def hide(&block)
        visible block ? proc { false == instance_eval(&block) } : false
      end
      alias_method :hidden, :hide
    end
  end
end
