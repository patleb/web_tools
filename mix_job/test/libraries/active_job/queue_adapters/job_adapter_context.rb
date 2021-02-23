class SimpleJob < ApplicationJob
  include Minitest::Assertions

  delegate :assertions, :assertions=, to: :$test

  def perform(user, *args)
    assert_equal $test.args, [user, *args]
  end
end

module JobAdapterContext
  extend ActiveSupport::Concern

  included do
    fixtures :users

    # since Rails 5.2, hash keys are converted to String
    let(:args){ [users(:admin), { 'a' => 1, 'b' => 2.0, 'c' => [{}.with_indifferent_access] }] }
    let(:scheduled_at){ 5.minutes.from_now }
  end
end
