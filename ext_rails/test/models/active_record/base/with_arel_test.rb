require './test/rails_helper'

class ActiveRecord::Base::WithArelTest < ActiveSupport::TestCase
  fixtures 'test/records', 'test/related_records'

  test '.column, .alias_table, .join, .greatest' do
    assert_equal 'text-2 Lorem Ipsum', Test::Record.find_second_with_related.label
  end
end
