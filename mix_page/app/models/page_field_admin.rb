module PageFieldAdmin
  extend ActiveSupport::Concern

  included do
    rails_admin do
      configure :page_template do
        hidden{ trash_action? }
      end

      fields :page_template, :name, :created_at, :updated_at

      index do
        sort_by :updated_at

        field :unscoped_page_template, weight: 0 do
          visible{ trash_action? }
        end
      end

      show do
        include_fields :creator, :updater
      end
    end
  end
end
