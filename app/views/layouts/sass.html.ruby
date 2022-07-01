html_('.no-js', lang: Current.locale, data: { theme: 'light' }) {[ # TODO Current.theme
  head_([
    area(:fonts, [
      # preload_pack_asset('sass')
    ]),
    area(:javascripts, [
      javascript_pack_tag('sass', defer: true),
    ]),
    area(:stylesheets, [
      stylesheet_pack_tag('sass', media: :all),
    ]),
    meta_(charset: 'utf-8'),
    meta_(name: 'viewport', content: 'width=device-width, initial-scale=1, shrink-to-fit=no'),
  ]),
  body_(tabindex: -1, class: ('debug-screens' if Rails.env.development?)) {[
    yield,
  ]}
]}
