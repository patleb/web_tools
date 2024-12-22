module Admin
  class GlobalPresenter < Admin::Model
    def self.label_plural
      'Globals'
    end

    navigation_key :system
    navigation_weight 60

    field :id
    field :expires
    field :expires_at

    index do
      filters [:all, :permanent, :expirable, :ongoing, :expired]
      field :data_type
      field :data do
        truncated true
      end
      field :updated_at
    end

    show do
      Global.data_types.except(:serialized).each_key do |type|
        field type do
          allowed{ presenter.data_type == type }
        end
      end
      field :serialized, type: :text do
        allowed{ presenter.data_type == :serialized }
      end
      field :updated_at
    end
  end
end
