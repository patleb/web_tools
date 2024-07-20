### References
# https://github.com/metaskills/minitest-spec-rails/blob/master/lib/minitest-spec-rails/dsl.rb

Minitest::Spec::DSL.class_eval do
  def xdescribe(desc, &block)
    # do nothing
  end
  alias_method :xcontext, :xdescribe
  alias_method :xtest, :xit

  module self::SpecBehavior
    extend ActiveSupport::Concern

    included do
      remove_method :test if method_defined? :test
    end

    class_methods do
      def describe(*args, &block)
        stack = Minitest::Spec.describe_stack
        stack.push self if stack.empty?
        super(*args) { class_eval(&block) }
        stack.pop if stack.length == 1
      end

      def before(_type = nil, &block)
        setup { instance_eval(&block) }
      end

      def after(_type = nil, &block)
        teardown { instance_eval(&block) }
      end

      def test(name, &block)
        instance_eval { it(name, &block) }
      end
    end
  end
end
