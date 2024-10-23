module Admin
  module Fields
    class Hstore < Admin::Field
      def parse_input!(params)
        params[column_name] = if params[column_name].blank?
          nil
        else
          YAML.safe_load(params[column_name])
        end
      end

      def format_value(value)
        value.to_yaml
      end
    end
  end
end
