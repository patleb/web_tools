html_('.no-js.no-transition', lang: Current.locale, data: { theme: Current.theme }, class: { debugger_host: ENV['DEBUGGER_HOST']}) {[
  head_([
    title_{ @meta[:title] },
    meta_(name: 'description', content: @meta[:description]),
    meta_(name: 'viewport', content: 'width=device-width, initial-scale=1'),
    meta_(name: 'view-transition', content: 'same-origin'),
    meta_(name: 'apple-mobile-web-app-capable', content: 'no'),
    meta_(name: 'mobile-web-app-capable', content: 'yes'),
    meta_(charset: 'UTF-8'),
    csrf_meta_tags,
    csp_meta_tag,
    area(:metas),
    area(:fonts),
    area(:javascripts),
    area(:stylesheets),
    # Enable PWA manifest for installable apps (make sure to enable in config/routes.rb too!)
    # tag.link(rel: 'manifest', href: pwa_manifest_path(format: :json)),
    area(:favicons, [
      favicon_link_tag('/icon.png', type: 'image/png'),
      favicon_link_tag('/icon.png', sizes: '192x192'),
      favicon_link_tag('/icon.png', rel: 'apple-touch-icon'),
    ]),
  ]),
  body_('.drawer', tabindex: -1, class: [body_layout, body_template, @meta[:class], ('debug-screens' if Rails.env.development?)]) {[
    area(:data, div_('.js_layout', data: { value: current_layout })),
    input_('#sidebar.drawer-toggle', type: 'checkbox'),
    div_('.drawer-content') {[
      header_('#header', [
        label_('.open_sidebar', for: 'sidebar') do
          span_ [icon('list'), a_('.link', @meta[:title], href: @meta[:root], title: @meta[:title])]
        end,
        area(:header, [
          spinner(ExtRails.config.spinner),
          flash_message(:alert, scope: @meta[:scope]),
          flash_message(:notice, scope: @meta[:scope]),
        ]),
      ]),
      main_('#main', yield),
      footer_('#footer') do
        area(:footer)
      end
    ]},
    div_('.drawer-side') {[
      label_('.drawer-overlay', for: 'sidebar'),
      aside_('.sidebar', [
        label_('.close_sidebar.menu', for: 'sidebar') do
          span_ [icon('x-square'), a_('.link', @meta[:app], href: @meta[:root], title: @meta[:app])]
        end,
        nav_('.nav_sidebar.menu', area(:sidebar)),
      ]),
    ]},
  ]}
]}
