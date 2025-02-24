module Admin
  class TaskPresenter < Admin::Model
    navigation_group_key :system
    navigation_weight 60

    field :name do
      translated false
    end
    field :description do
      truncated true
    end
    field :state,   editable: false
    field :updated_at
    field :duration_avg
    field :output,  editable: false, type: :code
    nests :updater, as: :email
    field :notify do
      readonly{ !presenter.notify_editable? }
    end
    field :perform do
      readonly{ presenter.running? }
    end

    index do
      sort_by :name
      exclude_fields :output, :perform
    end
  end
end
