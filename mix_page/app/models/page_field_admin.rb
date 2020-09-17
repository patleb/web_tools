module PageFieldAdmin
  extend ActiveSupport::Concern

  included do
    rails_admin do
      fields :page_template, :name, :created_at, :updated_at

      index do
        sort_by :updated_at
      end

      show do
        include_fields :creator, :updater
      end
    end
  end
end
