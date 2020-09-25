module PageFields::LinkAdmin
  extend ActiveSupport::Concern

  included do
    rails_admin do
      navigation_parent false

      field :fieldable, weight: 3 do
        searchable false
      end
    end
  end
end
