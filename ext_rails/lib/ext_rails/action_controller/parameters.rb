MonkeyPatch.add{['actionpack', 'lib/action_controller/metal/strong_parameters.rb', '90e20ad065d56051e7954d6315cd7c3118458fc29799c575d9dc4f72b97417e6']}

require 'action_controller/metal/strong_parameters'

module ActionController::Parameters::WithLocation
  def unpermitted_parameters!(params, **)
    if super && ExtRails.config.params_debug
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

  delegate :with_indifferent_access, :with_keyword_access, :to_hwia, :to_hwka, to: :to_hash
end
