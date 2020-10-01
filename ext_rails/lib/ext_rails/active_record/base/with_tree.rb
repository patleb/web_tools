# TODO
# on update, :level cannot be greater than the immediate parent or lesser than 0 (add scope functionality)
#   - do not modify :level on move within the list or on delete
#   - modify :level only on move within the same list's :position and use the immediate parent or set at 0 on none
#   - use cron job to re-adjust :level gaps
#   - on frontend, use max :level to set possible increment/decrement values
#   - on frontend, use jquery-ui sortable to move on the x axis with empty divs for increment/decrement values
#     --> similar to https://github.com/zorab47/active_admin-sortable_tree
module ActiveRecord::Base::WithTree
  extend ActiveSupport::Concern

  class_methods do
    def has_tree
      class_attribute :tree_column, instance_writer: false, default: :level

      attribute :tree_parent_id, :integer
      attribute :tree_increment, :integer
      attribute :tree_decrement, :integer

      include ActiveRecord::Base::WithTree::Level
    end
  end
end

module ActiveRecord::Base::WithTree::Level
end
