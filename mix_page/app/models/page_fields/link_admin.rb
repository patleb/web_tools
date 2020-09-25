module PageFields::LinkAdmin
  extend ActiveSupport::Concern

  included do
    rails_admin do
      navigation_parent false

      field :fieldable, weight: 3
    end
  end
end
