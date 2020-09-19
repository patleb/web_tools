module PageFieldAdmin
  extend ActiveSupport::Concern

  included do
    rails_admin do
      fields :page_template, :name, :updated_at, :updater, :created_at, :creator

      index do
        sort_by :updated_at
      end
    end
  end
end
