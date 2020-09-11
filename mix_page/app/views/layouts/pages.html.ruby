append :fonts, [
  preload_link_tag_bootswatch_fonts(:paper),
]

append :html_data, [
  div_('#js_routes_paths', data: { paths: MixPage.js_routes }),
]

extends 'layouts/mix_template/main', [
  render_pjax,
  remote_console
]
