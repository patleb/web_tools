module Admin
  module Fields
    class Hstore < Admin::Field
      def parse_input!(params)
        params[name] = if params[name].blank?
          nil
        else
          YAML.safe_load(params[name])
        end
      end

      def format_value(value)
        value.to_yaml
      end
    end
  end
end
