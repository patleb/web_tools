html_('.no-js', lang: Current.locale, data: { theme: params[:theme] == 'dark' ? 'dark' : 'light' }) {[
  head_([
    no_turbolinks,
    javascript_pack_tag('pico', defer: true, 'data-turbolinks-track': 'reload'),
    stylesheet_pack_tag('pico', media: :all),
    meta_(charset: 'utf-8'),
    meta_(name: 'viewport', content: 'width=device-width, initial-scale=1, shrink-to-fit=no'),
    csrf_meta_tags,
    csp_meta_tag,
    title_{ template_virtual_path.classify },
  ]),
  body_(class: template_virtual_path.full_underscore) {[
    yield,
  ]}
]}
