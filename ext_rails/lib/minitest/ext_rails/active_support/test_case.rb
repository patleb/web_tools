ActiveSupport::TestCase.class_eval do
  extend Minitest::Spec::DSL
  include Minitest::Spec::DSL::SpecBehavior

  class_attribute :delete_tables, instance_predicate: false, instance_accessor: false, default: []

  # Run tests in parallel with specified workers
  # parallelize(workers: :number_of_processors)

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  # fixtures :all

  # Add more helper methods to be used by all tests here...

  def self.order_dependent!
    Minitest::Test.order_dependent!
    self.test_order = :alpha
  end

  def self.test_queue_adapter!
    around do |test|
      queue_adapter_was = ActiveJob::Base.queue_adapter
      ActiveJob::Base.queue_adapter = :test
      test.call
      ActiveJob::Base.queue_adapter = queue_adapter_was
    end
  end

  def before_setup
    Rails.application.routes_reloader.execute_unless_loaded
    $test = self
    super
  end

  alias_method :run_without_clear_tables, :run
  def run(...)
    result = run_without_clear_tables(...)
    _clear_tables unless use_transactional_tests
    result
  end

  private

  def _clear_tables
    return unless (tables = self.class.delete_tables).present?
    ActiveRecord::Base.connection.execute tables.map{ |table| <<-SQL.strip_sql(table_name: table) }.join(' ')
      DELETE FROM "{{ table_name }}";
    SQL
  end
end
