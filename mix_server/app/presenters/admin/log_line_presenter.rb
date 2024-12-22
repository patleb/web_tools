module Admin
  class LogLinePresenter < Admin::Model
    def self.primary_key
      'created_at'
    end

    navigation_weight 100

    field :created_at
  end
end
