### References
# https://github.com/grosser/maxitest

Minitest::Spec::DSL.class_eval do
  remove_method :before
  remove_method :after
  alias_method :test, :it
  alias_method :context, :describe

  def xdescribe(desc)
    xit desc
  end
  alias_method :xcontext, :xdescribe

  def xit(desc)
    describe 'skip' do
      define_method(:setup) {}
      define_method(:teardown) {}
      it desc do
        skip desc
      end
    end
  end
  alias_method :xtest, :xit

  def pending(reason = nil, **options)
    return yield if options.fetch(:if, true) == false
    begin
      yield
    rescue StandardError, Minitest::Assertion
      skip reason
    else
      flunk "Test is fixed, remove 'pending'"
    end
  end

  def let_all(name, &block)
    cache = []
    define_method(name) do
      if cache.empty?
        cache << instance_eval(&block)
      end
      cache.first
    end
  end

  def let!(name, &block)
    let(name, &block)
    before{ send(name) }
  end

  def around(*args, &block)
    raise ArgumentError, "only :each or no argument is supported" if args != [] && args != [:each]
    fib = nil
    before do
      fib = Fiber.new do |context, resume|
        begin
          context.instance_exec(resume, &block)
        rescue Object
          fib = :failed
          raise
        end
      end
      fib.resume(self, lambda{ Fiber.yield })
    end
    after{ fib.resume if fib && fib != :failed }
  end

  module self::SpecBehavior
    extend ActiveSupport::Concern

    included do
      class_attribute :before_all_count, instance_predicate: false, instance_writer: false, default: 0
    end

    class_methods do
      def before(type = :each, &block)
        if type == :all
          count = self.before_all_count += 1
          callback = :"before_hook_all_#{count}"
          let_all(callback, &block)
          before{ public_send(callback) }
        else
          mod = Module.new do
            define_method :setup do
              super()
              instance_eval(&block)
            end
          end
          include mod
        end
      end

      def after(_type = :each, &block)
        mod = Module.new do
          define_method :teardown do
            instance_eval(&block)
          ensure
            super()
          end
        end
        include mod
      end
    end
  end
end
