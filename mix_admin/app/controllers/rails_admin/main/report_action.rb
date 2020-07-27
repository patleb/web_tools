module RailsAdmin::Main
  module ReportAction
    # TODO https://github.com/strzibny/invoice_printer
    def report
      render main_section.options.reverse_merge(pdf: main_section.name, template: main_section.template, layout: main_section.layout)
    end
  end
end
