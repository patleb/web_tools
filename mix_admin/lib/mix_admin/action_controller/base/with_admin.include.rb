module ActionController::Base::WithAdmin
  extend ActiveSupport::Concern

  included do
    helper_method :admin_root_path
  end

  def admin_root_path
    model = MixAdmin.config.root_model_name
    if can? model, :index
      MixAdmin::Routes.index_path(model_name: model.to_admin_param)
    elsif can? Current.user, :show
      MixAdmin::Routes.show_path(model_name: 'user', id: Current.user.id)
    else
      application_path
    end
  end
end
