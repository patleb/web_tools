ActiveJob::TestCase.class_eval do
  include ActionMailer::TestHelper
  include ActionMailer::TestCase::ClearTestDeliveries
end
