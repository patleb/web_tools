# TODO
# x
#  x
#   x
#    x
# oooox
# x
# -x
# --x
# ---x
# ----x
# --x
# ---x
# x cannot be greater than the immediate parent
# --> on move up/down, previous chidren will need to be adjusted to new parent and current value relative to new parent
#     sibling = order(:position).where(position > current.position).where(level <= current.level).first
#
#     where(id: children_ids).order(:id).update_all(childrens_level + (new_parent_level - old_parent_level))
#     [parent, current].sort_by(:id).each(&:lock)
#     current.level = parent.level + 1 if current > parent + 1
# --> on delete, chidrent will need to be adjusted
#
# use Ltree instead https://github.com/zorab47/active_admin-sortable_tree
module ActiveRecord::Base::WithTree
  extend ActiveSupport::Concern

  class_methods do
    def has_tree
      class_attribute :tree_column, instance_writer: false, default: :level

      attribute :tree_increment, :integer
      attribute :tree_decrement, :integer

      include ActiveRecord::Base::WithTree::Level
    end
  end
end

module ActiveRecord::Base::WithTree::Level
end
