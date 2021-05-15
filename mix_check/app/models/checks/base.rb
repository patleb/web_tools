module Checks
  class Base < VirtualRecord::Base
    def self.current
      first
    end

    def self.counter_value(new_value, old_value)
      (new_value < old_value) ? new_value : new_value - old_value
    end

    def self.validates(attribute, **options)
      return super unless options[:check]
      check_name = :"#{attribute}_check"
      define_method check_name do
        if send(attribute)&.issue?
          errors.add(attribute, :check_error)
        end
      end
      validate check_name
    end

    def self.ar_issues?
      __callbacks[:validate].any? do |callback|
        callback.filter.is_a?(ActiveModel::Validator) || callback.filter.end_with?('_check')
      end
    end

    def self.issue?
      any?(&:issue?)
    end

    def self.issue_predicates
      @issue_predicates ||= instance_methods.select(&:end_with?.with('_issue?'))
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

    def issue?
      self.class.ar_issues? ? !valid? : self.class.issue_predicates.any?{ |issue| send(issue) }
    end

    def issue_names(expand = true, warning: false)
      issue = warning ? :warning : :issue
      has_issue = :"#{issue}?"
      if self.class.send("ar_#{issue}s?")
        send(has_issue)
        names = errors.attribute_names
        nested_names = names & self.class.nested_attribute_names.map(&:to_sym)
        names = names - nested_names
      else
        names = self.class.send("#{issue}_predicates").except(:"nested_#{issue}?").select_map do |name|
          next unless send(name)
          name.to_s.delete_suffix("_#{issue}?").to_sym
        end
        nested_names = self.class.nested_attribute_names.select_map{ |name| send(name)&.send(has_issue) && name.to_sym }
      end
      if expand
        issue_names = "#{issue}_names"
        names.concat(
          nested_names.map do |name|
            { name => Array.wrap(send(name)).select(&has_issue).map{ |row| { row[:id] => row.send(issue_names) } } }
          end
        )
      else
        names.concat(nested_names)
      end
      names
    end

    def nested_issue?
      self.class.nested_attribute_names.any?{ |name| send(name)&.issue? }
    end

    def warning?
      self.class.warning_predicates.any?{ |warning| send(warning) }
    end

    def warning_names(expand = true)
      issue_names(expand, warning: true)
    end

    def nested_warning?
      self.class.nested_attribute_names.any?{ |name| send(name)&.warning? }
    end
  end
end
