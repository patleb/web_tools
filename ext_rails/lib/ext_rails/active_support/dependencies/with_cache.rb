MonkeyPatch.add{['activesupport', 'lib/active_support/dependencies.rb', '1866b869fc883e54b5dc93f4277fe3350b94b2f050690da6d0ea3d99ee89e8f9']}

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
