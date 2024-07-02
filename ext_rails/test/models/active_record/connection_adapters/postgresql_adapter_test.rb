require './test/rails_helper'

class ActiveRecord::ConnectionAdapters::PostgreSQLAdapterTest < ActiveSupport::TestCase
  test 'TableDefinition' do
    # NOTE :limit 53 used to be necessary
    assert_equal 'double precision', Test::Record.columns_hash['double'].sql_type
  end
end
