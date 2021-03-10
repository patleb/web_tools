require "active_support/dependencies"

module ActiveSupport::Dependencies::WithProfile
  def require_or_load(file_name, const_path = nil)
    if ENV['RAILS_PROFILE']
      if (result = Benchmark.realtime{ super }) > 0.005
        $profile_dependencies << "#{'%.5f' % result} #{file_name}"
      end
    else
      super
    end
  end
end

module ActiveSupport
  module Dependencies
    class << self
      prepend ActiveSupport::Dependencies::WithProfile
    end
  end
end
