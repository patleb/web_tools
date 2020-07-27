# Deprecation --> https://github.com/rails/rails/commit/c7820d8124c854760a4d288334f185de2fb99446
module MixTemplate
  module LayoutHelper
    def extends(layout, *args, &block)
      # Make sure it's a string
      layout = layout.to_s

      # If there's no directory component, presume a plain layout name
      layout = "layouts/#{layout}" unless layout.include?('/')

      # Capture the content to be placed inside the extended layout
      @view_flow.get(:layout).replace capture(*args, &block)

      render template: layout
    end
  end
end
