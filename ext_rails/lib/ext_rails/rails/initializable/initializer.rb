module Rails::Initializable::Initializer::SkippedInitializers
  extend ActiveSupport::Concern

  prepended do
    delegate :assets_initializers, :exclude_initializers, to: :class
  end

  class_methods do
    def assets_initializers
      @assets_initializers ||= Set.new
    end

    def exclude_initializers
      @exclude_initializers ||= {}
    end
  end

  def run(...)
    unless skip_run?
      if ENV['RAILS_PROFILE']
        if (result = Benchmark.realtime{ super }) > 0.05
          $profile_initializers << "#{'%.5f' % result} [#{@context.class.name}] => #{name}"
        end
      else
        super
      end
    end
  end

  def skip_run?
    if name == :append_assets_path # skip all sprockets initializers (webpacker should be the only tool used)
      return false if assets_initializers.include? @context.class.name
      return true
    end
    exclude_initializers[@context.class.name]&.include? name.to_s
  end
end

Rails::Initializable::Initializer.prepend Rails::Initializable::Initializer::SkippedInitializers
