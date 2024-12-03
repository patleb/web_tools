module PageFields
  class Text < PageField
    json_translate text: :string

    def field_label_values
      [page_template&.title || t('link.website')] + super
    end
  end
end
