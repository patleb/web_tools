module ExtCss
  has_config do
    attr_writer :variables

    def variables
      @variables ||= ['stylesheets/theming.css']
    end
  end
end
