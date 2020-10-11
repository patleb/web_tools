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
      edit do # TODO allow to create page in modal (not support for polymorphic association at the moment)
        configure :page_template do
          self.weight = 1
        end
      end
    end
  end
end
