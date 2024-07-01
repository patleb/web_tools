require './test/rails_helper'

class ActiveRecord::Base::WithDiscardTest < ActiveSupport::TestCase
  fixtures 'test/records', 'test/related_records'

  test '.default_scope, .discardable?' do
    assert_equal 5, Test::Record.all.size
    assert_equal true, Test::Record.discardable?
  end

  test '.discarded, .undiscarded, .with_discarded, .discard_all, .undiscard_all, #discard_all, #undiscard_all' do
    assert_equal [1, 5], [Test::Record.discarded, Test::Record.all].map(&:size)
    assert_equal [1, 5], [Test::RelatedRecord.discarded, Test::RelatedRecord.all].map(&:size)
    Test::Record.discard_all!
    assert_equal [6, 5], [Test::Record.discarded, Test::RelatedRecord.discarded].map(&:size)
    record = Test::Record.with_discarded.find(1)
    assert_equal 4, record.related_records.size

    Test::Record.undiscard_all!
    assert_equal [6, 6], [Test::Record.all, Test::RelatedRecord.all].map(&:size)
    record = Test::Record.find(1)
    assert_equal 4, record.related_records.size
  end

  test '#discard, #discarded?, #undiscard, #undiscarded?, #show?' do
    record = Test::Record.find(1)
    assert_equal true, record.undiscarded?
    assert_equal true, record.discard!
    assert_equal true, record.discarded?
    record.reload
    assert_equal true, record.undiscard!
    assert_equal true, record.undiscarded?
    assert_equal true, record.show?
  end
end
