module Admin
  class UserSessionPresenter < Admin::Model
    def self.primary_key
      'session_id'
    end

    navigation_i18n_key :system
    record_label_method :session_id
    simplify_search_string false

    index do
      advanced_search false
      countless true

      nests :user do
        field :email
      end
      field :session_id
      field :ip_address do
        queryable false
      end
      field :user_agent
      field :created_at
      field :updated_at
    end
  end
end
