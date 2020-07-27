class RailsAdmin::Config::Model::Sections::Report < RailsAdmin::Config::Model::Sections::Base
  register_instance_option :available? do
    false
  end

  register_instance_option :name do
    "#{@abstract_model.param_key}_report-#{@model.with(object: object).object_label.dehumanize}"
  end

  register_instance_option :template do
    "rails_admin/reports/#{@abstract_model.param_key}_report"
  end

  register_instance_option :layout do
    "layouts/rails_admin/reports"
  end

  register_instance_option :options do
    {
      # show_as_html: true,
      # javascript_delay: 2000,
      # window_status: 'done',
      # ~792px
      page_size: 'Letter',
      margin: {
        top: '10mm', bottom: '10mm', right: '2mm', left: '2mm'
      }
    }
  end
end
