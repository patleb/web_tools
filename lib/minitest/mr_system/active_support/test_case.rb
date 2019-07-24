# TODO assert_enqueued_email_with
ActiveSupport::TestCase.class_eval do
  after do
    Current.reset
  end
end
