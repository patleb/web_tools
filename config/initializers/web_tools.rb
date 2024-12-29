ExtRails.configure do |config|
  config.params_debug = false
  config.excluded_models.merge(%w(
    Test::ApplicationRecord
  ))
  config.css_only_support = true
  config.db_partitions.merge!(
    test_much_records: 5,
    test_time_series: :week,
  )
end

MixSearch.config.available_types['Test::Record'] = 20

MixTask.configure do |config|
  config.admin_names.concat(%w(
    try:sleep
  ))
end

MixServer.configure do |config|
  # config.render_500 = true
  config.skip_notice = false
end

MixPage.configure do |config|
  config.available_templates.merge!(
    'text_multi' => 10,
    'list'       => 20,
    'list/multi' => 25,
  )
  config.available_field_names.merge!(
    list_texts: 20,
  )
end

MixAdmin.configure do |config|
  config.included_models += %w(
    Test::%
  )
  config.excluded_models += %w(
    Test::ObjectRecord
    Test::MuchRecord
    Test::TimeSerie
    Test::TimeSeries::DataPoint
  )
end
