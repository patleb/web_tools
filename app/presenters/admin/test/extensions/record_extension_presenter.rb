module Admin::Test
  module Extensions
    class RecordExtensionPresenter < RecordPresenter
      field :attr_date
      field :attr_date_time
      field :attr_decimal
      field :attr_integer
      field :attr_json
      field :attr_password
      field :attr_string
      field :attr_text
      field :attr_time
      field :attr_value do
        help "Any value"
      end

      base do
        exclude_columns [:json]
        exclude_fields :json
      end

      show do
        group :virtual do
          help "Lorem Ipsum is simply dummy text of the printing and typesetting industry."

          field :virt_date
          field :virt_date_time
          field :virt_decimal
          field :virt_integer
          field :virt_json
          field :virt_password
          field :virt_string
          field :virt_text
          field :virt_time
          field :virt_value
        end
      end

      index do
        description "Lorem Ipsum is simply dummy text of the printing and typesetting industry.
          Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an
          unknown printer took a galley of type and scrambled it to make a type specimen book.
          It has survived not only five centuries, but also the leap into electronic typesetting,
          remaining essentially unchanged. It was popularised in the 1960s with the release of
          Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing
          software like Aldus PageMaker including versions of Lorem Ipsum."

        filters [:all, :today]
        countless true
      end
    end
  end
end
