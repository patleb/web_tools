module PageFields::LinkAdmin
  extend ActiveSupport::Concern

  included do
    rails_admin_prepend PageFields::Text

    rails_admin do
      navigation_parent false

      field :fieldable, weight: 2 do
        searchable false
      end
    end

    rails_admin :superclass, after: true do
      edit do
        configure :page_template do
          self.weight = 1
        end
      end
    end
  end
end
