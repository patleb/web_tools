require './test/test_helper'

class ActionController::WithErrorsTest < ActionDispatch::IntegrationTest
  self.use_transactional_tests = false

  test '#render_500' do
    assert_emails(1) do
      controller_test :render_500 do
        raise 'error'
      end
      assert Log.where(log_lines_type: 'LogLines::Rescue').exists?
      assert LogMessage.where('text_tiny LIKE ?', '%error%').exists?
    end
    assert_response :internal_server_error
    assert_select '.rails-default-error-page'
    assert body.to_s.include?('(500)')
  end

  test '#render_408' do
    assert_emails(1) do
      controller_test :render_408 do
        ActiveRecord::Base.with_timeout 1 do
          ActiveRecord::Base.connection.select_value 'SELECT pg_sleep(2)'
        end
      end
      assert Log.where(log_lines_type: 'LogLines::Rescue').exists?
      assert LogMessage.where('text_tiny LIKE ?', '%error%').exists?
    end
    assert_response :request_timeout
    assert_select '.rails-default-error-page'
    assert body.to_s.include?('(408)')
  end

  test '#render_400' do
    controller_test :render_408 do
      raise ActionController::BadRequest
    end
    assert_response :bad_request
    assert_select '.rails-default-error-page'
    assert body.to_s.include?('(400)')
  end
end
