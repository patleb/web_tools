module ActionController::Base::WithUserRouting
  def after_sign_out_path_for(*)
    if defined?(MixAdmin) && Current.referer.match?(%r{^#{RailsAdmin.root_path}(/|$|\?)})
      get_root_path
    else
      Current.referer
    end
  end

  def after_update_path_for(resource)
    after_sign_out_path_for(resource)
  end

  def after_inactive_sign_up_path_for(resource)
    after_sign_out_path_for(resource)
  end
end
