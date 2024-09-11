module Admin
  module Fields
    class Password < String
      def self.has?(section, property)
        property.name.to_s.match? /(^|_)password(_|$)/
      end

      register_option :pretty_value do
        '*****'
      end

      register_option :view_helper do
        :password_field
      end

      def allowed_field?
        super && section.is_a?(Admin::Sections::Edit)
      end

      def parse_input!(params)
        if params[name].present?
          params[name] = params[name]
        else
          params.delete(name)
        end
      end

      def format_value(value)
        ''.html_safe
      end

      def value
        ''
      end
    end
  end
end
