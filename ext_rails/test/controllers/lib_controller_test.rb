require './test/test_helper'

class LibControllerTest < ActionDispatch::IntegrationTest
  test 'index' do
    get '/test/records'
    assert_response :ok
    assert_equal '/', self[:@meta][:root]
    assert_equal 'Web Tools', self[:@meta][:app]
    assert_equal 'Web Tools', self[:@meta][:title]
    assert_select '#notice ~ .alert-info'
    assert_select '.table_wrapper'
    assert_select '.sticky'
    refute self[:@presenters].empty?
    assert self[:@template].present?
  end
end
