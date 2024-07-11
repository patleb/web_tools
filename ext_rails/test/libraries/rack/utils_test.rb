require './test/rails_helper'

class Rack::UtilsTest < ActiveSupport::TestCase
  test '.merge_url' do
    assert_url '/path?p_1=v_1', 'path', p_1: 'v_1'
    assert_url '/path?p_1=v_2', 'path?p_1=v_1', p_1: 'v_2'
    assert_url '/path?p_1=v_1&p_2=v_2', 'path?p_1=v_1', p_2: 'v_2'
    path = "/path?#{{ p: { p_1: [0, 1], p_2: 'v_2' } }.to_query}"
    assert_url "#{path}&p_3=true", path, p_3: true
  end

  private

  def assert_url(expected, url, params)
    assert_equal expected, Rack::Utils.merge_url(url, params: params)
  end
end
