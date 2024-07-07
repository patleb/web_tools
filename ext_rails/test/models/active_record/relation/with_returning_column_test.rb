require './test/rails_helper'

class ActiveRecord::Relation::WithReturningColumnTest < ActiveSupport::TestCase
  fixtures 'test/records'

  test '.update_all' do
    assert_equal [5, false], Test::Record.update_all({ boolean: false }, :boolean)
    assert_equal 2, Test::Record.where(id: 1).update_all('integer = integer + 1', :integer)
  end
end
