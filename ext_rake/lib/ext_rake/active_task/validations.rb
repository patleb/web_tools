module ActiveTask
  module Validations
    def validates_greater!(name, minimum)
      value = options[name]
      raise ArgumentError, "--#{name.to_s.dasherize} must be > #{minimum}" unless value && value > minimum
    end

    def validates_greater_or_equal!(name, minimum)
      value = options[name]
      raise ArgumentError, "--#{name.to_s.dasherize} must be >= #{minimum}" unless value && value >= minimum
    end
  end
end
