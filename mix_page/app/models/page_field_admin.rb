module PageFieldAdmin
  extend ActiveSupport::Concern

  included do
    rails_admin :base_class do
      field :name do
        searchable false
        index_value{ primary_key_link(pretty_value) }
      end
      fields :page_template, :updated_at, :updater, :created_at, :creator do
        searchable false
      end
    end
  end
end
