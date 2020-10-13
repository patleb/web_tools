class RailsAdmin::Config::Model::Fields::Discarded < RailsAdmin::Config::Model::Fields::Datetime
  register_instance_option :visible? do
    trash_action? && visible_field?
  end

  def editable?
    false
  end
end
