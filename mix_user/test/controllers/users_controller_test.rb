require './test/test_helper'
require_relative './users/test_help'

class UsersControllerTest < Users::TestCase
  test '#new' do
    get '/users/new'
    assert_response :success
    assert_unauthenticated
    assert_select 'form.new_user'
  end

  test '#create' do
    assert_difference 'User.count + UserSession.count', 2 do
      assert_emails(1) do
        post '/users/new', params: { user: create_params }
      end
    end
    assert_redirected_to root_path
    assert_notice
    assert_session_created
  end

  context 'with invalid password' do
    test '#create' do
      assert_no_enqueued_emails do
        post '/users/new', params: { user: invalid_params }
      end
      assert_response :unprocessable_content
      assert_alert
      assert_select 'input[name="user[password]"][value]', false
      assert_select 'input[name="user[password_confirmation]"][value]', false
    end
  end

  context 'verified' do
    let!(:user){ User.create! create_params }

    test '#edit' do
      get '/users/verified/edit', params: { token: user.generate_token_for(:verified) }
      assert_redirected_to root_path
      assert_notice
      assert_unauthenticated
      assert user.reload.verified?
    end

    context 'with blank token' do
      test '#edit' do
        get '/users/verified/edit'
        assert_redirected_to root_path
        assert_alert
      end
    end
  end

  context 'deleted' do
    let!(:user){ User.create! create_params.merge(deleted_at: Time.current) }

    test '#edit' do
      get '/users/deleted/edit', params: { token: user.generate_token_for(:deleted) }
      assert_redirected_to root_path
      assert_notice
      assert user.reload.undiscarded?
    end

    context 'with invalid token' do
      test '#edit' do
        get '/users/deleted/edit', params: { token: 'invalid' }
        assert_redirected_to root_path
        assert_alert
      end
    end
  end

  context 'password' do
    let!(:user){ User.create! create_params.merge(verified_at: Time.current) }

    test '#edit' do
      get '/users/password/edit', params: { token: user.generate_token_for(:password) }
      assert_response :success
      assert_select 'form.edit_user'
      token = user.generate_token_for(:password)
      travel MixUser.config.reset_expires_in + 1.second
      get '/users/password/edit', params: { token: token }
      assert_redirected_to root_path
      assert_alert
    end

    test '#update' do
      Current.session_id = 'unknown'
      user.create_session! ip_address: '0.0.0.0', user_agent: 'none'

      post '/users/password/edit', params: { token: user.generate_token_for(:password), user: update_params }
      assert_redirected_to MixUser::Routes.new_session_path
      assert_notice
      assert_equal 0, user.reload.sessions.size
      assert_session_destroyed
    end
  end

  private

  def create_params
    { email: 'example@test.com', password: 'password' * 2, password_confirmation: 'password' * 2 }
  end

  def invalid_params
    { email: 'example@test.com', password: 'password', password_confirmation: 'password' }
  end

  def update_params
    { password: 'pass' * 3, password_confirmation: 'pass' * 3 }
  end
end
