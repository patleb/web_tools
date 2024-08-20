### References
# https://github.com/grosser/maxitest
# https://github.com/metaskills/minitest-spec-rails

Minitest::Skip.class_eval do
  def backtrace
    []
  end
end

Minitest::Spec::DSL.class_eval do
  remove_method :before
  remove_method :after
  alias_method :test, :it

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

    def let(name, value)
      name = name.to_s
      value_was = public_send(name)
      @_memoized[name] = value
      yield if block_given?
    ensure
      @_memoized[name] = value_was if block_given?
    end

    class_methods do
      def describe(*args, &block)
        stack = Minitest::Spec.describe_stack
        stack.push self if stack.empty?
        super(*args){ class_eval(&block) }
        stack.pop if stack.length == 1
      end
      alias_method :context, :describe

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

      def after(type = :each, &block)
        raise ArgumentError, ':all is not supported in after, use Minitest.after_run' if type == :all
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
