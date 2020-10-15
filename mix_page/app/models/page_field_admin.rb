module PageFieldAdmin
  extend ActiveSupport::Concern

  included do
    rails_admin :base_class do
      navigation_parent 'PageTemplate'

      field :lock_version
      field :name do
        searchable false
      end
      fields :page_template do
        searchable false
        queryable false
      end
      fields :updated_at, :created_at, weight: 90 do
        searchable false
        queryable false
      end
    end

    rails_admin :base_class, after: true do
      index do
        sort_action_columns{ ['page_id', 'name'].concat(sort_action_columns) }
      end

      edit do
        fields :updater, :creator, weight: 100
      end
    end
  end
end
