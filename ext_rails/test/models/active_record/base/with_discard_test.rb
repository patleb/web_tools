require './test/rails_helper'

class ActiveRecord::Base::WithDiscardTest < ActiveSupport::TestCase
  fixtures 'test/records', 'test/related_records'

  test '.default_scope, .discardable?' do
    assert_equal 5, Test::Record.all.size
    assert_equal true, Test::Record.discardable?
  end

  test '.discarded, .undiscarded, .with_discarded, .discard_all, .undiscard_all, #discard_all, #undiscard_all' do
    assert_equal 1, Test::RelatedRecord.discarded.size
    assert_equal 5, Test::RelatedRecord.undiscarded.size
    Test::Record.discard_all!
    assert_equal 6, Test::Record.discarded.size
    assert_equal 4, Test::RelatedRecord.discarded.size
    Test::Record.undiscard_all!
    assert_equal 6, Test::Record.undiscarded.size
    assert_equal 6, Test::RelatedRecord.undiscarded.size
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
