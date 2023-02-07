# NOTE https://github.com/rails/rails/commit/3c90308b175de54cd120f65b113ee774aec203b2
module ActiveSupport::Dependencies::WithCache
  extend ActiveSupport::Concern

  class_methods do
    def clear
      ActiveSupport::Dependencies.unload_interlock do
        String::Reference.clear!
      end
      super
    end
  end
end

ActiveSupport::Dependencies.prepend ActiveSupport::Dependencies::WithCache
