devise_flash_messages

append :devise_title do
  t('.sign_up')
end

append :devise_form do
  form_for(resource, as: resource_name, url: registration_path(resource_name), html: { role: 'form' }) { |f| [
    div_('.form-group') {[
      f.label(:email),
      f.email_field(:email, autofocus: true, autocomplete: "email", required: true, class: 'form-control')
    ]},
    div_('.form-group') {[
      f.label(:password),
      em_(if: @minimum_password_length) do
        t('devise.shared.minimum_password_length', count: @minimum_password_length)
      end,
      f.password_field(:password, autocomplete: "new-password", required: true, class: 'form-control')
    ]},
    div_('.form-group') {[
      f.label(:password_confirmation),
      f.password_field(:password_confirmation, autocomplete: "new-password", required: true, class: 'form-control')
    ]},
    f.submit(t('.sign_up'), class: 'btn btn-primary')
  ]}
end

render 'devise/shared/links'
