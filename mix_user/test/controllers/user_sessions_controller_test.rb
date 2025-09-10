require './test/test_helper'
require_relative './users/test_help'

class UserSessionsControllerTest < Users::TestCase
  test '#new' do
    get '/user_sessions/new'
    assert_response :success
    assert_unauthenticated
    assert_select 'form.new_user'
  end

  context 'with user' do
    let!(:user){ User.create! create_params.merge(password_confirmation: create_params[:password]) }

    test '#create' do
      post '/user_sessions/new', params: { user: create_params }
      assert_redirected_to root_path
      assert_notice
      assert_session_created
    end

    context 'with invalid password' do
      test '#create' do
        post '/user_sessions/new', params: { user: invalid_params }
        assert_response :unprocessable_content
        assert_alert
        assert_select 'input[name="user[password]"][value]', false
      end
    end

    context 'verified' do
      test '#create' do
        user.verified!
        assert_no_enqueued_emails do
          post '/user_sessions/new?edit=verified', params: { user: create_params.slice(:email) }
        end
        user.unverified!
        assert_enqueued_email_with UserMailer, :verify_email, params: { user: user } do
          post '/user_sessions/new?edit=verified', params: { user: create_params.slice(:email) }
        end
        assert_redirected_to root_path
        assert_notice
      end
    end

    context 'deleted' do
      test '#create' do
        user.verified!
        user.undiscard!
        assert_no_enqueued_emails do
          post '/user_sessions/new?edit=deleted', params: { user: create_params.slice(:email) }
        end
        user.discard!
        assert user.unverified?
        assert_enqueued_email_with UserMailer, :restore_user, params: { user: user } do
          post '/user_sessions/new?edit=deleted', params: { user: create_params.slice(:email) }
        end
        assert_redirected_to root_path
        assert_notice
      end
    end

    context 'password' do
      test '#create' do
        user.unverified!
        assert_no_enqueued_emails do
          post '/user_sessions/new?edit=password', params: { user: create_params.slice(:email) }
        end
        user.verified!
        assert_enqueued_email_with UserMailer, :reset_password, params: { user: user } do
          post '/user_sessions/new?edit=password', params: { user: create_params.slice(:email) }
        end
        assert_redirected_to root_path
        assert_notice
      end
    end

    test '#destroy' do
      post '/user_sessions/new', params: { user: create_params }
      assert_session_created
      post '/user_sessions/current/delete'
      assert_session_destroyed
      assert_redirected_to root_path
      assert_notice
    end
  end

  private

  def create_params
    { email: 'example@test.com', password: 'password' * 2 }
  end

  def invalid_params
    { email: 'example@test.com', password: 'password' }
  end
end
