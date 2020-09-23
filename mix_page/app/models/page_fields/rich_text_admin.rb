module PageFields::RichTextAdmin
  extend ActiveSupport::Concern

  included do
    rails_admin do
      navigation_parent false

      field :text, :wysiwyg, translated: :all
    end
  end
end
