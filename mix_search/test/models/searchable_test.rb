require './test/test_helper'

class SearchableTest < ActiveSupport::TestCase
  fixtures 'test/records', 'test/related_records'

  test '.update_searches, .similar_to' do
    Test::Record.update_searches
    records = Test::Record.similar_to('name')
    assert_equal [1, 2, 3, 4, 5], records.map(&:id).sort
    records = Test::Record.similar_to('related')
    assert_equal [1], records.map(&:id).sort
    records = Test::Record.similar_to('TeXt+3', 'rélate')
    assert_equal [1, 3], records.map(&:id).sort
  end
end
