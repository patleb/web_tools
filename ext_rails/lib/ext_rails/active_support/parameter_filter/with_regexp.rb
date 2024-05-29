MonkeyPatch.add{['activesupport', 'lib/active_support/parameter_filter.rb', 'b9f9831c53b4cd2fab2d9297540ed92037c15e2422483fbeb0523fd771633940']}

require 'active_support/parameter_filter'

module ActiveSupport
  ParameterFilter.class_eval do
    private

    def compile_filters!(filters)
      @no_filters = filters.empty?
      return if @no_filters

      @regexps, strings = [], []
      @deep_regexps, deep_strings = nil, nil
      @blocks = nil

      filters.each do |item|
        case item
        when Proc
          (@blocks ||= []) << item
        when Regexp
          if item.to_s.include?("\\.")
            (@deep_regexps ||= []) << item
          else
            @regexps << item
          end
        else
          s = Regexp.escape(item.to_s)
          if s.include?("\\.")
            (deep_strings ||= []) << s
          else
            strings << s
          end
        end
      end

      @regexps << Regexp.new(strings.join("|"), 'i') unless strings.empty?
      (@deep_regexps ||= []) << Regexp.new(deep_strings.join("|"), 'i') if deep_strings
    end
  end
end
