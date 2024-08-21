# frozen_string_literal: true

min = MixUser.config.min_password_length
i18n = i18n_for(
  'activerecord.attributes.user' => [:email, :password, :password_confirmation],
  'link' => :sign_up,
)
append :title, i18n[:sign_up]

form_(action: MixUser::Routes.new_path, remote: true, as: @user) {[
  input_(type: 'hidden', name: '_back', value: back_path, as: false),
  div_('.form-control', label_('.input-group', [
    icon('envelope', tag: 'span'),
    input_('.input.input-bordered',
      type: 'email',
      name: 'email',
      placeholder: i18n[:email],
      autofocus: true,
      required: true,
      autocomplete: 'email',
    )
  ])),
  div_('.form-control', label_('.input-group', [
    icon('key', tag: 'span'),
    input_('.input.input-bordered',
      type: 'password',
      name: 'password',
      placeholder: i18n[:password],
      minlength: min,
      required: true,
      autocomplete: 'new-password',
    )
  ])),
  div_('.form-control', label_('.input-group', [
    icon('key-fill', tag: 'span'),
    input_('.input.input-bordered',
      type: 'password',
      name: 'password_confirmation',
      placeholder: i18n[:password_confirmation],
      minlength: min,
      required: true,
      autocomplete: 'new-password',
    )
  ])),
  input_('.btn.btn-active.btn-primary', type: 'submit', value: i18n[:sign_up])
]}
