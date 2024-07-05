# frozen_string_literal: true

MonkeyPatch.add{['actionpack', 'lib/action_controller/metal/strong_parameters.rb', '00ec459ed48c35be561f6b3137fb8220a09695fdc297c73405e894cadcac04a2']}

require 'action_controller/metal/strong_parameters'

module ActionController::Parameters::WithLocation
  def unpermitted_parameters!(params)
    if super && ExtRails.config.params_debug?
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

  delegate :with_indifferent_access, to: :to_hash
end
