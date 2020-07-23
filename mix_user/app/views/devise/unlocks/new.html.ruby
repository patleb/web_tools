append :devise_title do
  t('.resend_unlock_instructions')
end

append :devise_form do
  form_for(resource, as: resource_name, url: unlock_path(resource_name), html: { method: :post, role: "form" }) { |f| [
    div_('.form-group') {[
      f.label(:email),
      f.email_field(:email, autofocus: true, autocomplete: "email", required: true, class: 'form-control')
    ]},
    f.submit(t('.resend_unlock_instructions'), class: 'btn btn-primary')
  ]}
end

render 'devise/shared/links'
