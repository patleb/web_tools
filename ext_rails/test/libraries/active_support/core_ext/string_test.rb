require './test/rails_helper'

class StringTest < ActiveSupport::TestCase
  test '#strip_sql' do
    assert_equal 'SELECT something FROM another WHERE id BETWEEN 1 AND 2;', <<-SQL.strip_sql(var_1: 1, var_2: 2)
      SELECT something FROM another -- comment after
       WHERE        id BETWEEN {{ var_1 }} AND {{ var_2 }};
    SQL
  end

  test '#compile_sql' do
    assert_equal "'SELECT ($1).' || id || ', name || ''_next''' INTO local USING val_1, val_2", <<-SQL.compile_sql(pk: :id)
      SELECT ($1).[{{ pk }}], name || '_next' -- comment here
      [INTO local] [USING val_1, val_2]
    SQL
    assert_equal "'SELECT id FROM names' USING value", <<-SQL.compile_sql('{}', table: :names)
      SELECT id FROM {{ table }} {USING value}
    SQL
  end
end
