module PageFields::TitleAdmin
  extend ActiveSupport::Concern

  included do
    rails_admin_prepend PageFields::Text

    rails_admin do
      navigation_parent false
    end
  end
end
