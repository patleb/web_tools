html_('.no-js', lang: Current.locale) {[
  head_ {[
    wicked_pdf_javascript_include_tag(current_layout('vendor')),
    wicked_pdf_javascript_include_tag(current_layout),
    wicked_pdf_stylesheet_link_tag(current_layout),
    area(:head),
    meta_('http-equiv': 'content-type', content: 'text/html; charset=utf-8'),
    meta_(name: 'description', content: @page_description ),
    title_{ @page_title },
  ]},
  body_(id: module_name) do
    yield
  end
]}
