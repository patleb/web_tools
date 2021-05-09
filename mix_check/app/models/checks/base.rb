# TODO
# https://pgdash.io/features
# https://pganalyze.com/docs
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

    def self.ar_errors?
      __callbacks[:validate].any? do |callback|
        callback.filter.is_a?(ActiveModel::Validator) || callback.filter.end_with?('_check')
      end
    end

    def self.error?
      any?(&:error?)
    end

    def self.error_predicates
      @error_predicates ||= instance_methods.select(&:end_with?.with('_error?'))
    end

    def self.ar_warnings?
      false
    end

    def self.warning?
      any?(&:warning?)
    end

    def self.warning_predicates
      @warning_predicates ||= instance_methods.select(&:end_with?.with('_warning?'))
    end

    def error?
      self.class.ar_errors? ? !valid? : self.class.error_predicates.any?{ |error| send(error) }
    end

    def error_names(expand = true, warning: false)
      error = warning ? :warning : :error
      has_error = :"#{error}?"
      if self.class.send("ar_#{error}s?")
        send(has_error)
        names = send("#{error}s").attribute_names
        nested_names = names & self.class.nested_attribute_names.map(&:to_sym)
        names = names - nested_names
      else
        names = self.class.send("#{error}_predicates").except(:"nested_#{error}?").select_map do |name|
          next unless send(name)
          name.to_s.delete_suffix("_#{error}?").to_sym
        end
        nested_names = self.class.nested_attribute_names.select_map{ |name| send(name).send(has_error) && name.to_sym }
      end
      if expand
        error_names = "#{error}_names"
        names.concat(
          nested_names.map do |name|
            { name => Array.wrap(send(name)).select(&has_error).map{ |row| { row[:id] => row.send(error_names) } } }
          end
        )
      else
        names.concat(nested_names)
      end
      names
    end

    def nested_error?
      self.class.nested_attribute_names.any?{ |name| send(name).error? }
    end

    def warning?
      self.class.warning_predicates.any?{ |warning| send(warning) }
    end

    def warning_names(expand = true)
      error_names(expand, warning: true)
    end

    def nested_warning?
      self.class.nested_attribute_names.any?{ |name| send(name).warning? }
    end
  end
end
