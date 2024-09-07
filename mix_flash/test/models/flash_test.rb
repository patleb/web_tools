require './test/test_helper'
require './mix_flash/test/support/flash_context'

class FlashTest < ActiveSupport::TestCase
  include FlashContext

  let(:messages){ { alert: 'Alert Error', notice: 'Notice Warning' } }

  test '.[], .[]=, .messages, .dequeue_all, .current' do
    Flash[:alert] = 'Alert'
    Flash[:alert] += ' Error'
    Flash[:notice] = 'Notice Warning'
    assert_equal messages[:alert], Flash[:alert]
    assert_equal messages[:notice], Flash[:notice]
    assert_equal messages, Current.flash.messages
    Flash.current.save!
    assert_equal messages, Flash.messages
    assert_equal({}, Flash.messages)
  end

  test '.cleanup' do
    Flash[:alert] = 'Error'
    Flash.current.save!
    Flash.current.update! updated_at: MixFlash.config.flash_expires_in.ago
    Flash.cleanup
    assert_equal({}, Flash.messages)
  end

  test '.validates' do
    flash = Flash.new
    flash.valid?
    assert_equal [:messages, :session_id, :user_id], flash.errors.attribute_names.sort
  end
end
