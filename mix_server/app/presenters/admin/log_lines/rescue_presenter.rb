module Admin
  class LogLines::RescuePresenter < Admin::LogLinePresenter
    nests :log_message, as: :text
  end
end
