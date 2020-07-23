purge :devise_error_messages

append :devise_title do
  t('.sign_in')
end

append :devise_form do
  form_for(resource, as: resource_name, url: session_path(resource_name), html: { role: 'form' }) { |f| [
    div_('.form-group') {[
      f.label(:email),
      f.email_field(:email, autofocus: true, autocomplete: "email", required: true, class: 'form-control')
    ]},
    div_('.form-group') {[
      f.label(:password),
      f.password_field(:password, autocomplete: "current-password", required: true, class: 'form-control')
    ]},
    div_('.checkbox', if: devise_mapping.rememberable?) do
      f.label(:remember_me) {[
        f.check_box(:remember_me),
        t('.remember_me')
      ]}
    end,
    f.submit(t('.sign_in'), class: 'btn btn-primary')
  ]}
end

render 'devise/shared/links'
