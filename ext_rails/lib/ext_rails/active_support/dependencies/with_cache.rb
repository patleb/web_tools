MonkeyPatch.add{['activesupport', 'lib/active_support/dependencies.rb', '2b11940364ba3f0b10c9b4338a1fac14e2dcbb29c5b1b13c92e29f2ec460f67d']}

# NOTE https://github.com/rails/rails/commit/3c90308b175de54cd120f65b113ee774aec203b2
module ActiveSupport::Dependencies::WithCache
  extend ActiveSupport::Concern

  class_methods do
    def clear
      unload_interlock do
        String::Reference.clear!
      end
      super
    end
  end
end

ActiveSupport::Dependencies.prepend ActiveSupport::Dependencies::WithCache
