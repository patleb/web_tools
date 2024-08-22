i18n = i18n_for('user_mailer.verify_email' => {
  nil => [:instruction, :action],
  greeting: { recipient: @user.email },
})

h_(
  p_{ i18n[:greeting] },
  p_{ i18n[:instruction] },
  p_{ a_ i18n[:action], href: MixUser::Routes.edit_verified_url(token: @token) },
)