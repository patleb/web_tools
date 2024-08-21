i18n = i18n_for('user_mailer.reset_password' => {
  nil => [:instruction, :instruction_2, :instruction_3, :action],
  greeting: { recipient: @user.email },
})

h_(
  p_{ i18n[:greeting] },
  p_{ i18n[:instruction] },
  p_{ a_ i18n[:action], href: MixUser::Routes.edit_password_url(token: @token) },
  p_{ i18n[:instruction_2] },
  p_{ i18n[:instruction_3] },
)
