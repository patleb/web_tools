require './test/rails_helper'

module ActiveRecord::Relation::WithRetry
  def find_or_create_by!(...)
    return super unless $test.try(:retry) && !@retried
    @retried = true
    create!(...)
  rescue ActiveRecord::RecordNotUnique
    retry
  end
end
ActiveRecord::Relation.prepend ActiveRecord::Relation::WithRetry

class ActiveRecord::Relation::WithAtomicOperationsTest < ActiveSupport::TestCase
  fixtures 'test/records'

  let(:retry){ true }

  test '.find_or_create_by!!' do
    record = Test::Record.find_or_create_by!(id: 1)
    assert_equal true, record.persisted?
    assert_equal 1, record.id
    assert_equal 'Name', record.name
  end
end
