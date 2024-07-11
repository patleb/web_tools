require './test/rails_helper'

class GearedPagination::ControllerTest < ActionDispatch::IntegrationTest
  let(:scope){ Test::Record.all }
  let(:per_page){ 2 }

  test '.set_page_and_extract_portion_from' do
    assert_page -1,   result: [1, 2]
    assert_page  0,   result: [1, 2]
    assert_page  1,   result: [1, 2]
    assert_page  nil, result: [1, 2]
    assert_page  2,   result: [3, 4]
    assert_page  3,   result: [5]
    assert_page  4,   result: []
  end

  context 'as countless' do
    test '.set_page_and_extract_portion_from' do
      assert_page '', result: [1, 2]
      assert_page     result: [3, 4]
      assert_page     result: [5]
      assert_page     result: []
    end
  end

  private

  def assert_page(*n, result:)
    n = n.empty? ? $test.result&.dig(:next) : n.first
    $test.result = {}
    countless = !(n.nil? || n.is_a?(Integer))
    controller_assert "paginate#{"_p#{n}" if n}#{"_sorted" if countless}", params: n ? { p: n } : {} do
      $test.result.merge!(if countless; {
        scope: set_page_and_extract_portion_from($test.scope, per_page: $test.per_page, ordered_by: :id),
        count: paginator.recordset.records.count_estimate,
      } else {
        scope: set_page_and_extract_portion_from($test.scope, per_page: $test.per_page),
        count: paginator.recordset.records_count,
        pages: paginator.recordset.page_count,
      } end).merge!(
        number: paginator.number,
        next: paginator.next_param,
        first: paginator.first?,
        last: paginator.last?,
      )
    end
    if countless
      scope, count, number, next_n, first, last = $test.result.values_at(:scope, :count, :number, :next, :first, :last)
      assert_equal result, scope.pluck(:id)
      assert next_n
      case number
      when 1
        assert_equal true, first
        assert_equal false, last
      when 2
        assert_equal false, first
        assert_equal false, last
      when 3, 4
        assert_equal false, first
        assert_equal true, last
      end
    else
      scope, count, number, next_n, first, last, pages = $test.result.values_at(:scope, :count, :number, :next, :first, :last, :pages)
      assert_equal result, scope.order(:id).pluck(:id)
      assert_equal 3, pages
      case n
      when nil, 0, 1
        assert_equal 1, number
        assert_equal 2, next_n
        assert_equal true, first
        assert_equal false, last
      when 2, 3, 4
        assert_equal n, number
        assert_equal n + 1, next_n
        assert_equal false, first
        assert_equal n == 3, last
      end
    end
    assert_equal 5, count
  end
end
