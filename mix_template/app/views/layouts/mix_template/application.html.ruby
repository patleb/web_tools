html_('.no-js', lang: Current.locale) {[
  head_([
    unless Rails.env.test? && !$test.is_a?(ActionDispatch::SystemTestCase)
      [
        area(:fonts, [
          link_(rel: 'preconnect', href: 'https://fonts.gstatic.com', crossorigin: 'anonymous'),
          link_(rel: 'preconnect', href: 'https://cdn.jsdelivr.net', crossorigin: 'anonymous'),
          preload_link_tag_bootswatch_fonts(MixTemplate.config.theme),
          preload_link_tag("https://cdn.jsdelivr.net/npm/katex@#{MixTemplate.config.katex_version}/dist/fonts/KaTeX_Main-Regular.woff2"),
          preload_link_tag("https://cdn.jsdelivr.net/npm/katex@#{MixTemplate.config.katex_version}/dist/fonts/KaTeX_Math-Italic.woff2"),
        ]),
        area(:javascripts, [
          javascript_packs_with_chunks_tag(current_layout, defer: true),
        ]),
        area(:stylesheets, [
          preload_pack_asset('media/fonts/fontawesome-webfont.woff2'),
          stylesheet_packs_with_chunks_tag(current_layout, media: :all),
          stylesheet_link_tag("https://cdn.jsdelivr.net/npm/katex@#{MixTemplate.config.katex_version}/dist/katex.min.css", media: :all),
        ]),
        area(:favicons, [
          favicon_link_tag('/favicon.png', type: 'image/png', sizes: '32x32'), # TODO browsers call by default favicon.ico
          favicon_link_tag('/apple-touch-icon.png', rel: 'apple-touch-icon', type: 'image/png', sizes: '192x192'),
          favicon_link_tag('/apple-touch-icon-precomposed.png', rel: 'apple-touch-icon-precomposed', type: 'image/png'),
        ]),
      ]
    end,
    meta_(charset: 'utf-8'),
    meta_(name: 'viewport', content: 'width=device-width, initial-scale=1, shrink-to-fit=no'),
    meta_(name: 'description', content: @page_description),
    # TODO make sure that navigation is self-sufficient
    meta_(name: 'mobile-web-app-capable', content: 'yes', if: @page_web_app_capable),
    meta_('http-equiv': 'X-PAGE-VERSION', content: @page_version),
    csrf_meta_tags,
    csp_meta_tag,
    area(:metas),
    title_{ @page_title },
    browser_upgrade_css
  ]),
  body_(id: body_id, class: body_class) {[
    browser_upgrade_html,
    area(:html_data),
    yield,
  ]}
]}
