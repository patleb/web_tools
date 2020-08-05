RailsAdmin.configure do |config|
  config.included_models = %w(
    Global
    User
  )
  config.excluded_models = %w(
  )

  config.actions do
    index
    # chart
    export
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
