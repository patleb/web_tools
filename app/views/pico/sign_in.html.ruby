h_(
  nav_('.container-fluid', [
    ul_(
      li_(brand)
    ),
    ul_([
      li_(theme_menu(direction: 'rtl', role: 'link', class: 'secondary')),
      li_(examples_menu(direction: 'rtl', role: 'link', class: 'secondary')),
    ]),
  ]),
  main_('.container', [
    article_('.grid', [
      div_([
        hgroup_([
          h1_('Sign in'),
          h2_('A minimalist layout for Login pages'),
        ]),
        form_(action: '/pico/sign_in', remote: true, multipart: true) {[
          input_(type: 'text', name: 'login', placeholder: 'Login', 'aria-label': 'Login', autocomplete: 'nickname', required: true),
          input_(type: 'password', name: 'password', placeholder: 'Password', 'aria-label': 'Password', autocomplete: 'current-password', required: true),
          fieldset_(
            label_(for: 'remember') {[
              input_(type: 'checkbox', role: 'switch', id: 'remember', name: 'remember'),
              'Rember me'
            ]}
          ),
          input_(name: 'file', type: 'file'),
          button_('.contrast', 'Login', type: 'submit')
        ]}
      ]),
      div_,
    ]),
  ]),
  footer_('.container-fluid', footer_text)
)
