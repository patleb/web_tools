MixPage.configure do |config|
  config.root_template = 'home'
  config.max_children_count = 1

  config.available_templates.merge!(
    'generic_multi' => 0,
    'home' => 10,
    'list' => 20,
    'list/tree' => 30,
    'list/multi' => 25,
    'list/tree/multi' => 35,
  )
  config.available_field_names.merge!(
    'sidebar_links' => 0,
    'page_list_texts' => 10,
    'page_texts' => 20,
  )
end

RailsAdmin.configure do |config|
  config.root_model_name = 'PageTemplate'

  config.included_models = %w(
    Global
    PageTemplate
    PageField
    PageFields::%
    Rescue
    User
  )
  config.excluded_models = %w(
    PageFields::Text
  )

  config.actions do
    index
    # chart
    export
    sort
    new
    trash
    show
    edit
    # clone
    delete
    show_in_app
    restore
    bulk_delete
    # choose
    # report
  end
end
