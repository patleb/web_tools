### References
# https://github.com/rwz/nestive
module ActionView::Helpers
  module CaptureHelper
    def extends(layout, &)
      layout = layout.to_s
      layout = "layouts/#{layout}" unless layout.include? '/'
      @view_flow.get(:layout).replace capture(&)
      (@layouts ||= []) << layout.delete_prefix('layouts/')
      render template: layout
    end

    def area(name, content = nil, &)
      content = capture(&) if block_given?
      append name, content
      render_area name
    end

    def append(name, content = nil, &)
      content = capture(&block) if block_given?
      add_instruction_to_area name, :push, content
    end

    def prepend(name, content = nil, &)
      content = capture(&block) if block_given?
      add_instruction_to_area name, :unshift, content
    end

    def replace(name, content = nil, &)
      content = capture(&) if block_given?
      add_instruction_to_area name, :replace, [content]
    end

    def purge(*names)
      names.each{ |name| replace(name, nil)}
    end

    private

    def add_instruction_to_area(name, instruction, value)
      @_area_for ||= {}
      @_area_for[name] ||= []
      @_area_for[name] << [instruction, value]
      nil
    end

    def render_area(name)
      [].tap do |output|
        @_area_for.fetch(name, []).reverse_each do |method_name, content|
          output.public_send method_name, content
        end
      end.join.html_safe
    end
  end
end
