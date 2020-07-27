extends 'layouts/mix_template/main/pjax', [
  div_('#js_main_model', data: { model: @abstract_model.to_param }),
  div_('#js_main_action', data: { action: main_action }),
  div_({ id: "#{main_action}_action", class: "#{@abstract_model.param_key}_model" }, [
    ul_('.contextual_menu.nav.nav-tabs', [
      menu_for(@abstract_model, @object),
      area(:contextual_tabs)
    ]),
    yield
  ])
]
