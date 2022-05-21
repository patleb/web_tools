html_('.no-js', lang: Current.locale, data: { theme: params[:theme] == 'dark' ? 'dark' : 'light' }) {[
  head_([
    javascript_pack_tag('coffee', defer: true, 'data-turbolinks-track': 'reload'),
    stylesheet_pack_tag('coffee', media: :all),
    meta_(charset: 'utf-8'),
    meta_(name: 'viewport', content: 'width=device-width, initial-scale=1, shrink-to-fit=no'),
    csrf_meta_tags,
    csp_meta_tag,
    title_{ @page_title },
  ]),
  body_([
    yield,
  ])
]}
