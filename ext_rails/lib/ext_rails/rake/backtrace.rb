# frozen_string_literal: true

require 'rake/backtrace'

module Rake
  module Backtrace
    suppressed_paths = SUPPRESSED_PATHS.reject do |path|
      !path.include?('rake') && path.end_with?('lib', 'ruby')
    end
    suppressed_paths_re = suppressed_paths.map{ |f| Regexp.quote(f) }.join("|")
    suppress_pattern = %r!(\A(#{suppressed_paths_re})|bin/rake:\d+)!i
    remove_const :SUPPRESS_PATTERN
    SUPPRESS_PATTERN = suppress_pattern
  end
end
