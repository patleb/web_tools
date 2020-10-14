class RailsAdmin::Config::Model::Fields::Association::ListParent < RailsAdmin::Config::Model::Fields::Association::BelongsTo
  register_instance_option :visible? do
    sort_action? && visible_association?
  end

  def editable?
    false
  end
end
