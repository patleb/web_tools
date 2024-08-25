require './test/test_helper'

class ActionController::WithContextTest < ActionDispatch::IntegrationTest
  context '#set_current_locale' do
    test 'default' do
      head '/'
      assert_response :ok
      assert_locale :fr
    end

    test 'params[:_locale]' do
      head '/', params: { _locale: 'en' }
      assert_locale :en
    end

    test 'headers["X-Locale"]' do
      head '/', headers: { 'X-Locale' => 'en' }
      assert_locale :en
    end

    test 'headers["HTTP_ACCEPT_LANGUAGE"]' do
      head '/', headers: { 'HTTP_ACCEPT_LANGUAGE' => 'en' }
      assert_locale :en
    end
  end

  context '#set_current_timezone' do
    test 'default' do
      head '/'
      assert_timezone 'UTC'
    end

    test 'params[:_timezone]' do
      head '/', params: { _timezone: 'America/New_York' }
      assert_timezone 'America/New_York'
    end

    test 'params[:_timezone] integer' do
      head '/', params: { _timezone: '-18000' }
      assert_timezone 'Bogota'
    end

    test 'headers["X-Timezone"]' do
      head '/', headers: { 'X-Timezone' => 'America/New_York' }
      assert_timezone 'America/New_York'
    end
  end

  test '#without_timezone' do
    controller_assert :without_timezone, params: { _timezone: 'America/New_York' } do
      without_timezone do
        [Current.timezone, Time.zone.name].all?(&:==.with('UTC'))
      end
    end
  end

  private

  def assert_locale(locale)
    assert_equal locale.to_s, session[:locale]
    assert_equal locale.to_s, cookies[:_locale]
    assert_equal locale.to_sym, current[:locale]
  end

  def assert_timezone(timezone)
    assert_equal timezone, session[:timezone]
    assert_equal timezone, cookies[:_timezone]
    assert_equal timezone, current[:timezone]
  end
end
