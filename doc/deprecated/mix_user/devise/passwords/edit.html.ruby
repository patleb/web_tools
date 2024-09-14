devise_flash_messages

append :devise_title do
  t('.change_your_password')
end

append :devise_form do
  form_for(resource, as: resource_name, url: password_path(resource_name), html: { method: :put, role: 'form' }) { |f| [
    f.hidden_field(:reset_password_token),
    div_('.form-group') {[
      f.label(:password, t('.new_password')),
      em_(if: @minimum_password_length) do
        t('devise.shared.minimum_password_length', count: @minimum_password_length)
      end,
      f.password_field(:password, autofocus: true, autocomplete: 'new-password', required: true, class: 'form-control')
    ]},
    div_('.form-group') {[
      f.label(:password_confirmation, t('.confirm_new_password')),
      f.password_field(:password_confirmation, autocomplete: 'new-password', required: true, class: 'form-control')
    ]},
    f.submit(t('.change_my_password'), class: 'btn btn-primary')
  ]}
end

render 'devise/shared/links'
