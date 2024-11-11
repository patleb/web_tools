module Admin
  module Fields
    class Json < Admin::Field
      def editable?
        false
      end

      def method?
        true
      end

      def parse_input!(params)
        params[column_name] = parse_input(params[column_name]) if params[column_name].is_a? String
      end

      def parse_input(value)
        value.present? ? (ActiveSupport::JSON.decode(value) rescue nil) : nil
      end

      def format_value(value)
        value&.pretty_json(:html)
      end

      def format_index(value)
        return super unless truncated && value.include?('<br>')
        json = value.sub(/<br>.+/, '')
        json << if (url = presenter.viewable_url(anchor: "#{name}_field"))
          a_('.link.link-primary', ascii(:ellipsis), href: url)
        else
          ascii(:ellipsis)
        end
        json = json.html_safe if value.html_safe?
        json
      end
    end
  end
end
