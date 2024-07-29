class Minitest::TestCase < Minitest::Spec
  include Minitest::Spec::DSL::SpecBehavior
  include ActiveSupport::Testing::TimeHelpers

  def before_setup
    $test = self
    super
  end
end
