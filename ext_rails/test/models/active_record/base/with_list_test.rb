require './test/rails_helper'

Test::RelatedRecord.class_eval do
  alias_method :list_after_without_retry, :list_after
  def list_after(prev_record, &block)
    return list_after_without_retry(prev_record, &block) unless $test.try(:retry) && !@retried
    @retried = true
    self[:position] = 5.0
    yield
  end
end

class ActiveRecord::Base::WithListTest < ActiveSupport::TestCase
  fixtures 'test/records', 'test/related_records'

  test '#list_prev_id, #list_next_id, #list_change_only, .list_reorganize, .listables' do
    record = Test::Record.find(1)
    related = record.related_records
    assert_equal 4, related.size
    assert_equal [1, 2, 3, 5], related.order(:position).map(&:id)

    r3 = Test::RelatedRecord.find(3)
    r3.update! list_next_id: 2
    assert_equal [1, 3, 2, 5], related.order(:position).map(&:id)
    r3.update! list_next_id: 1
    assert_equal [3, 1, 2, 5], related.order(:position).map(&:id)
    r3.update! list_next_id: 3
    assert_equal [3, 1, 2, 5], related.order(:position).map(&:id)
    r3.update! list_next_id: 5
    assert_equal [1, 2, 3, 5], related.order(:position).map(&:id)
    r3.update! list_next_id: 5
    assert_equal [1, 2, 3, 5], related.order(:position).map(&:id)

    r2 = Test::RelatedRecord.find(2)
    r2.update! list_prev_id: 3
    assert_equal [1, 3, 2, 5], related.order(:position).map(&:id)
    r2.update! list_prev_id: 5
    assert_equal [1, 3, 5, 2], related.order(:position).map(&:id)
    r2.update! list_prev_id: 2
    assert_equal [1, 3, 5, 2], related.order(:position).map(&:id)
    r2.update! list_prev_id: 1
    assert_equal [1, 2, 3, 5], related.order(:position).map(&:id)
    r2.update! list_prev_id: 1
    assert_equal [1, 2, 3, 5], related.order(:position).map(&:id)

    r1 = Test::RelatedRecord.find(1)
    r1.update list_prev_id: 2, name: r1.name + " won't move"
    assert_equal [:list_change_only], r1.errors.map(&:type)

    assert_equal [0,1,2,4,3,5].zip([0.0, 1.0, 2.5, 4.0, 4.5, 5.0]), all_related_positions
    Test::RelatedRecord.list_reorganize(force: true)
    assert_equal [0,1,2,4,3,5].zip([0.0, 1.0, 2.0, 3.0, 4.0, 5.0]), all_related_positions

    assert_equal ['Test::RelatedRecord'], Test::ApplicationRecord.listables.map(&:name)
  end

  context 'with retry' do
    let(:retry){ true }

    test 'uniqueness' do
      r3 = Test::RelatedRecord.find(3)
      assert_raises ActiveRecord::RecordNotUnique do
        r3.update! list_prev_id: 5
      end
      r3.reload.update! list_prev_id: 5
      assert_equal 6.0, r3.position
    end
  end

  private

  def all_related_positions
    Test::RelatedRecord.with_discarded.order(:position).pluck(:id, :position)
  end
end
