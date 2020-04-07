append :devise_title do
  t('.resend_confirmation_instructions')
end

append :devise_form do
  email = (resource.pending_reconfirmation? ? resource.unconfirmed_email : resource.email)
  form_for(resource, as: resource_name, url: confirmation_path(resource_name), html: { method: :post, role: 'form' }) { |f| [
    div_('.form-group') {[
      f.label(:email),
      f.email_field(:email, autofocus: true, autocomplete: "email", value: email, required: true, class: 'form-control')
    ]},
    f.submit(t('.resend_confirmation_instructions'), class: 'btn btn-primary')
  ]}
end

render 'devise/shared/form'
