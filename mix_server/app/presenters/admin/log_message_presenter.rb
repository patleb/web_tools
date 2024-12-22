module Admin
  class LogMessagePresenter < Admin::Model
    field :id
    field :text, type: :code do
      truncated false
    end
  end
end
