require './test/test_helper'
require './mix_flash/test/support/flash_context'

class ActionController::Base::WithFlashTest < ActionDispatch::IntegrationTest
  include FlashContext

  test 'Flash.later, Flash.dequeue_in' do
    controller_test :flash_later do
      Current.user.sessions.first.update! session_id: session.id
      Current.session_id = session.id.to_s
      Flash[:alert] = 'Error'
      render html: 'flash later'
    end
    assert_equal nil, flash.now[:alert]

    controller_test :flash_now do
      Current.session_id = Current.user.sessions.first.sid
      render html: 'flash now'
    end
    assert_equal 'Error', flash.now[:alert]
  end
end
