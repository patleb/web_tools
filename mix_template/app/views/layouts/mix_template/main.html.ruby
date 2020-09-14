extends 'layouts/mix_template/application' do
  div_('.container-fluid') do
    div_('.row', [
      nav_('.navbar.navbar-default.col-sm-3.col-md-2') do
        div_ '.container-fluid' do
          div_('.navbar-header', [
            button_('.js_menu_toggle.navbar-toggle.collapsed', type: 'button', data: { toggle: 'collapse', target: '#navigation' }) {[
              span_('.sr-only', t('template.toggle_navigation')),
              span_('.icon-bar', times: 3)
            ]},
            a_('.navbar-brand', @app_name, href: @root_path, class: ('pjax' if @root_pjax)),
            div_('#js_page_title', @page_title)
          ])
        end
      end,
      div_('#navigation.navbar-collapse.collapse', role: 'navigation') do
        div_ '.sidebar-nav.col-sm-3.col-md-2' do
          area(:sidebar)
        end
      end,
      div_('#js_layout_window.col-sm-9.col-sm-offset-3.col-md-10.col-md-offset-2', [
        div_('.js_menu_overlay'),
        div_('#js_pjax_container') do
          yield
        end
      ])
    ])
  end
end
