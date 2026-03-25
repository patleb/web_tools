module Admin
  class LogLines::RescuePresenter < Admin::LogLinePresenter
    nests :log_message, as: :text

    index do
      searchable false
    end
  end
end
