# TODO probably won't work
extends 'layouts/mr_template/report' do[
  div_('#js_i18n_translations', data: { translations: js_i18n('admin.js') }),
  div_('#js_routes_paths', data: { paths: {} }),
  div_('#js_main_model', data: { model: @abstract_model.to_param }),
  div_('#js_flash_messages', data: { messages: [] }),
  div_('.container-fluid', class: "#{@abstract_model.param_key}_report") do
    yield
  end
]end
