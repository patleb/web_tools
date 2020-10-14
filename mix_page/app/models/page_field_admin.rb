module PageFieldAdmin
  extend ActiveSupport::Concern

  included do
    rails_admin :base_class do
      field :name do
        searchable false
        index_value{ primary_key_link(pretty_value) }
      end
      fields :parent, :page_template, :updated_at, :updater, :created_at, :creator do
        searchable false
        queryable false
      end
      # TODO find why sort doesn't work
      configure :updater do
        sortable false
      end
      configure :creator do
        sortable false
      end
      field :lock_version
    end
  end
end
