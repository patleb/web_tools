html_('.no-js', lang: Current.locale) {[
  head_ {[
    content_for?(:javascripts) ? yield(:javascripts) : [
      javascript_packs_with_chunks_tag(current_layout, defer: true),
    ],
    content_for?(:stylesheets) ? yield(:stylesheets) : [
      stylesheet_packs_with_chunks_tag(current_layout, media: :all),
    ],
    area(:fonts),
    area(:preload_tags),
    content_for?(:favicons) ? yield(:favicons) : [
      favicon_link_tag('/favicon.png', type: 'image/png', sizes: '32x32'),
      favicon_link_tag('/apple-touch-icon.png', rel: 'apple-touch-icon', type: 'image/png', sizes: '192x192'),
      favicon_link_tag('/apple-touch-icon-precomposed.png', rel: 'apple-touch-icon-precomposed', type: 'image/png'),
    ],
    meta_(charset: 'utf-8'),
    meta_(name: 'viewport', content: 'width=device-width, initial-scale=1, shrink-to-fit=no'),
    meta_(name: 'description', content: @page_description),
    meta_(name: 'mobile-web-app-capable', content: 'yes', if: MixTemplate.config.web_app_capable),
    meta_('http-equiv': 'X-APP-VERSION', content: MixTemplate.config.version),
    csrf_meta_tags,
    csp_meta_tag,
    area(:meta_tags),
    title_{ @page_title },
    browser_upgrade_css
  ]},
  body_(id: body_id) {[
    browser_upgrade_html,
    area(:html_data),
    yield,
    (remote_console if defined? MixUser)
  ]}
]}
