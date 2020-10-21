append(:sidebar_links) {[
  layout_sidebar,
  hr_('.separator'),
  ul_('.nav.nav-pills.nav-stacked') {[
    li_{ a_ 'Application', href: app_root_path }
  ]},
]}

extends 'layouts/pages', [
  render_pjax,
]
