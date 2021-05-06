module Checks
  class Base < VirtualRecord::Base
    def self.validates(attribute, **options)
      return super unless options[:check]
      check_name = :"#{attribute}_check"
      define_method check_name do
        if send(attribute).error?
          errors.add(attribute, :check_error)
        end
      end
      validate check_name
    end

    def self.error?
      any?(&:error?)
    end

    def self.warning?
      any?(&:warning?)
    end

    def error?
      self.class.methods.select(&:end_with?.with('_error?')).any?{ |error| send(error) }
    end

    def warning?
      self.class.methods.select(&:end_with?.with('_warning?')).any?{ |warning| send(warning) }
    end

    def nested_warning?
      self.class.nested_attribute_names.any?{ |name| send(name).warning? }
    end
  end
end
