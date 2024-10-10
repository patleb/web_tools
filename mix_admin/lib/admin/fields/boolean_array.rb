module Admin
  module Fields
    class BooleanArray < Boolean
      prepend Field::AsArray

      register_option :pretty_separator do
        '&nbsp;'.html_safe
      end
    end
  end
end
