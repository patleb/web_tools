module PageFields::RichTextAdmin
  extend ActiveSupport::Concern

  included do
    rails_admin do
      listable false

      configure :name do
        index_value{ primary_key_link(pretty_value) }
      end
      field :title, translated: :all do
        searchable false
      end
      field :text, :wysiwyg, translated: :all do
        searchable false
      end
    end

    rails_admin :superclass, after: true do
      index do
        exclude_fields :text
        exclude_fields :title, translated: true
      end

      edit do
        exclude_fields :title
      end
    end
  end
end
