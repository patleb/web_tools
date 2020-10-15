module PageFields::LinkAdmin
  extend ActiveSupport::Concern

  included do
    rails_admin_prepend PageFields::Text

    rails_admin do
      field :parent, weight: -1 do
        searchable false
        pretty_value{ value&.text }
      end
      configure :text, weight: 0 do
        index_value do
          primary_key_link(pretty_value || I18n.t('page_fields.edit', model: object.model_name.human.downcase))
        end
      end
      field :active, :boolean do
        readonly false
      end
    end

    rails_admin :superclass, after: true do
      index do
        field :fieldable, weight: 1
      end

      edit do
        field :fieldable, weight: 4
      end
    end
  end
end
