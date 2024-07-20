class Minitest::TestCase < Minitest::Spec
  include Minitest::Spec::DSL::SpecBehavior
  include ActiveSupport::Testing::TimeHelpers
end
