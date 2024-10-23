module Admin
  module Fields
    class Serialized < Text
      def self.yaml_load(yaml)
        YAML.safe_load(yaml)
      end

      def self.yaml_dump(object)
        YAML.dump(object)
      end

      def editable?
        false
      end

      def method?
        true
      end

      def parse_input!(params)
        params[column_name] = parse_value(params[column_name]) if params[column_name].is_a? String
      end

      def parse_value(value)
        value.present? ? (self.class.yaml_load(value) || nil) : nil
      end

      def format_value(value)
        self.class.yaml_dump(value) unless value.nil?
      end
    end
  end
end
