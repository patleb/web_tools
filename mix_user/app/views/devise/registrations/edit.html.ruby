devise_flash_messages

append :devise_title do
  t('.title', resource: resource.model_name.human)
end

append :devise_form do
  form_for(resource, as: resource_name, url: registration_path(resource_name), html: { method: :put }) { |f| [
    div_('.form-group') {[
      f.label(:email),
      f.email_field(:email, autofocus: true, autocomplete: "email", required: true, class: 'form-control')
    ]},
    div_(if: devise_mapping.confirmable? && resource.pending_reconfirmation?) do
      t('.currently_waiting_confirmation_for_email', email: resource.unconfirmed_email)
    end,
    div_('.form-group') {[
      f.label(:password),
      i_("(#{t '.leave_blank_if_you_don_t_want_to_change_it'})"),
      f.password_field(:password, autocomplete: "new-password", required: true, class: 'form-control'),
      em_(if: @minimum_password_length) do
        t('devise.shared.minimum_password_length', count: @minimum_password_length)
      end
    ]},
    div_('.form-group') {[
      f.label(:password_confirmation),
      f.password_field(:password_confirmation, autocomplete: "new-password", required: true, class: 'form-control')
    ]},
    div_('.form-group') {[
      f.label(:current_password),
      i_("(#{t '.we_need_your_current_password_to_confirm_your_changes'})"),
      f.password_field(:current_password, autocomplete: "current-password", required: true, class: 'form-control')
    ]},
    f.submit(t('.update'), class: 'btn btn-primary')
  ]}
end

replace :devise_links do
  ul_('.nav.nav-pills.nav-stacked') do
    li_(link_to t('.cancel_my_account'), registration_path(resource_name), data: { confirm: true }, method: :delete)
  end
end

render 'devise/shared/links'
