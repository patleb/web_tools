module Admin
  class PageFieldPresenter < Admin::Model
    record_label_method :field_label

    field :lock_version
    nests :page_template do
      field :view do
        pretty_blank{ presenter.website_link }
      end
    end
    field :name
    group :userstamps, label: false do
      nests :updater, as: :email
      nests :creator, as: :email
    end
    group :timestamps, label: false do
      field :updated_at
      field :created_at
    end

    def website_link
      a_ '.link.text-primary', t('link.website'), href: pages_root_path
    end
  end
end
