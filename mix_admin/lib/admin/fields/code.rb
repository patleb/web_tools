module Admin
  module Fields
    class Code < Text
      def editable?
        false
      end
    end
  end
end
