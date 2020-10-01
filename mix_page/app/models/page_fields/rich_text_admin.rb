module PageFields::RichTextAdmin
  extend ActiveSupport::Concern

  included do
    rails_admin do
      navigation_parent false

      field :title, translated: :all do
        searchable false
      end
      field :subtitle, translated: :all do
        searchable false
      end
      field :text, :wysiwyg, translated: :all do
        searchable false
      end
    end

    rails_admin :superclass, after: true do
      index do
        exclude_fields :title, :subtitle, translated: :all
      end

      edit do
        exclude_fields :title, :subtitle
      end
    end
  end
end
