ActiveSupport::TestCase.class_eval do
  # Run tests in parallel with specified workers
  # parallelize(workers: :number_of_processors)

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  # fixtures :all

  # Add more helper methods to be used by all tests here...

  let(:base_name){ $test.class.name.match(/^([\w:]+)Test(?:$|::)/)[1] }

  def self.order_dependent!
    Minitest::Test.order_dependent!
    self.test_order = :alpha
  end

  def before_setup
    $test = self
    super
  end

  before do
    VCR.turn_off!
  end
end
