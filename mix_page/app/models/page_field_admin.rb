module PageFieldAdmin
  extend ActiveSupport::Concern

  included do
    rails_admin do
      field :name do
        index_value{ primary_key_link(pretty_value) }
      end
      fields :page_template, :updated_at, :updater, :created_at, :creator
    end
  end
end
