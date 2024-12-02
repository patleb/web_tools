module Admin
  class PageFieldPresenter < Admin::Model
    record_label_method :field_label

    field :lock_version
    nests :page_template, as: :view
    field :name

    group :audit do
      label false
      nests :updater, as: :email
      nests :creator, as: :email
      field :updated_at
      field :created_at
    end
  end
end
