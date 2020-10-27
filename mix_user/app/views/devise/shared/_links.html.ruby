div_('#devise.panel.panel-default.col-sm-8.col-sm-offset-2.col-md-6.col-md-offset-3') {[
  div_('.row.panel-heading') do
    h5_{ area(:devise_title) }
  end,
  div_('.row.panel-body') do
    area(:devise_form)
  end,
  div_('.row.panel-footer') do
    area(:devise_links) do
      links = []
      if controller_name != 'sessions'
        links << link_to(t('.sign_in'), new_session_path(resource_name), class: 'pjax')
      end
      if devise_mapping.registerable? && controller_name != 'registrations'
        links << link_to(t('.sign_up'), new_registration_path(resource_name), class: 'pjax')
      end
      if devise_mapping.recoverable? && controller_name != 'passwords' && controller_name != 'registrations'
        links << link_to(t('.forgot_your_password'), new_password_path(resource_name), class: 'pjax')
      end
      if devise_mapping.confirmable? && controller_name != 'confirmations'
        links << link_to(t('.didn_t_receive_confirmation_instructions'), new_confirmation_path(resource_name), class: 'pjax')
      end
      if devise_mapping.lockable? && resource_class.unlock_strategy_enabled?(:email) && controller_name != 'unlocks'
        links << link_to(t('.didn_t_receive_unlock_instructions'), new_unlock_path(resource_name), class: 'pjax')
      end
      if devise_mapping.omniauthable?
        resource_class.omniauth_providers.each do |provider|
          links << link_to(t('.sign_in_with_provider', provider: OmniAuth::Utils.camelize(provider)), omniauth_authorize_path(resource_name, provider), class: 'pjax')
        end
      end
      if links.any?
        ul_('.nav.nav-pills.nav-stacked') do
          links.map{ |link| li_ link }
        end
      end
    end
  end
]}
