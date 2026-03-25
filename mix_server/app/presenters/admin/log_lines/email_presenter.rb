module Admin
  class LogLines::EmailPresenter < Admin::LogLinePresenter
    field :from
    field :to
    field :subject
    field :sent

    index do
      searchable false
    end
  end
end
