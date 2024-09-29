# frozen_string_literal: true

i18n = i18n_for(
  'activerecord.attributes.user' => [:email, :password],
  'link' => [:log_in, :resend_confirm, :restore_user, :reset_password],
)
append :title, i18n[:log_in]

form_(action: MixUser::Routes.new_session_path, remote: true, back: true, as: @user) {[
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
  if_(params[:edit] == 'verified'){[
    input_(type: 'hidden', name: 'edit', value: 'verified', as: false),
    input_('.btn.btn-active.btn-primary', type: 'submit', value: i18n[:resend_confirm])
  ]},
  elsif_(params[:edit] == 'deleted' && MixUser.config.restorable?){[
    input_(type: 'hidden', name: 'edit', value: 'deleted', as: false),
    input_('.btn.btn-active.btn-primary', type: 'submit', value: i18n[:restore_user])
  ]},
  elsif_(params[:edit] == 'password'){[
    input_(type: 'hidden', name: 'edit', value: 'password', as: false),
    input_('.btn.btn-active.btn-primary', type: 'submit', value: i18n[:reset_password])
  ]},
  else_(
    div_('.form-control', label_('.input-group', [
      icon('key', tag: 'span'),
      input_('.input.input-bordered',
        type: 'password',
        name: 'password',
        placeholder: i18n[:password],
        required: true,
        autocomplete: 'current-password',
      )
    ])),
    input_('.btn.btn-active.btn-primary', type: 'submit', value: i18n[:log_in])
  )
]}
