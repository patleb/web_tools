require 'action_controller/metal/strong_parameters'

module ActionController::Parameters::WithLocation
  def unpermitted_parameters!(params)
    super
    if MrSystem.config.params_debug \
    && unpermitted_keys(params).any? \
    && self.class.action_on_unpermitted_parameters == :log
      puts_caller_location
    end
  end

  def puts_caller_location
    index = nil
    location = caller_locations.find.with_index do |line, i|
      line = line.to_s
      if index.nil? && line.include?('lib/action_controller/metal/strong_parameters')
        index = i
        false
      elsif index && line.exclude?('lib/action_controller/metal/strong_parameters')
        true
      end
    end
    puts location
  end
end

ActionController::Parameters.class_eval do
  prepend self::WithLocation

  def with_keyword_access
    to_hash.with_keyword_access
  end
end
