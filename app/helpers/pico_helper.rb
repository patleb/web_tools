module PicoHelper
  def brand
    a_('.contrast', strong_('Brand'), href: '/pico')
  end

  def theme_menu(direction: nil, **options)
    details_(role: 'list', dir: direction) {[
      summary_('aria-haspopup': 'listbox', **options) {
        'Theme'
      },
      ul_(role: 'listbox') {[
        li_(a_ 'Default', href: '?'),
        li_(a_ 'Light', href: '?theme=light'),
        li_(a_ 'Dark', href: '?theme=dark'),
      ]}
    ]}
  end

  def examples_menu(direction: nil, **options)
    details_(role: 'list', dir: direction) {[
      summary_('aria-haspopup': 'listbox', **options) {
        'Examples'
      },
      ul_(role: 'listbox') {[
        li_(a_ 'Sign in', href: '/pico/sign_in'),
        li_(a_ 'Company', href: '/pico/company'),
      ]}
    ]}
  end

  def footer_text
    small_(['Built with', a_('Pico', href: 'https://picocss.com', target: '_blank'), '•', a_('Source code', href: 'https://github.com/picocss/examples/blob/master/basic-template/', target: '_blank')])
  end
end
