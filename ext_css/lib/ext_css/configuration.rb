module ExtCss
  has_config do
    attr_writer :variables
    attr_writer :spinner

    def variable(name, transform = nil)
      @variable ||= variables.each_with_object({}) do |path, memo|
        next unless (css = Pathname.new("app/javascript/#{path}")).exist?
        started = false
        css.each_line do |line|
          if !started
            next unless line.match? /^ *:root *\{/
            started = true
          elsif line.match? /^ *}/
            break
          elsif (match = line.match /^ *(--[a-z][a-z0-9-]*) *: *([^;]+) *;/)
            css_name, css_value = match.captures
            memo[css_name] = css_value
          end
        end
      end
      return unless (value = @variable[name]).present?
      value = value.public_send(transform) if transform
      value
    end

    def variables
      @variables ||= [
        'stylesheets/variables.css',
        'stylesheets/theming.css',
        "vendor/epic-spinners/stylesheets/#{spinner}_spinner.css"
      ]
    end

    def spinner
      @spinner ||= :atom
    end
  end
end
