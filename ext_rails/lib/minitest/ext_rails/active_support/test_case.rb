ActiveSupport::TestCase.class_eval do
  extend Minitest::Spec::DSL
  include Minitest::Spec::DSL::SpecBehavior

  # Run tests in parallel with specified workers
  # parallelize(workers: :number_of_processors)

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  # fixtures :all

  # Add more helper methods to be used by all tests here...

  def self.order_dependent!
    Minitest::Test.order_dependent!
    self.test_order = :alpha
  end

  def before_setup
    $test = self
    super
  end

  after do
    Current.reset
  end
end
