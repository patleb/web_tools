module TailwindHelper
  SVG_BEGIN = /^\s*<svg [^>]+>\s*/
  SVG_END = /\s*<\/svg>\s*$/
  SVG_ATTRIBUTES = { xmlns: 'http://www.w3.org/2000/svg', fill: 'currentColor', height: 16, width: 16, viewBox: '0 0 16 16', 'aria-hidden': true }

  # https://icon-sets.iconify.design/
  # https://boxicons.com/
  # https://materialdesignicons.com/
  # https://tabler-icons.io/
  # https://fonts.google.com/icons?selected=Material+Icons
  # https://heroicons.com/
  # https://lucide.dev/
  # https://icons.getbootstrap.com/
  def icon(name, **options)
    name = name.to_s.dasherize
    text = (@@_icon ||= {})[name] ||= begin
      Pathname.new("node_modules/bootstrap-icons/icons/#{name}.svg").read.sub!(SVG_BEGIN, '').sub!(SVG_END, '').html_safe
    end
    svg_attributes = SVG_ATTRIBUTES.merge(options[:svg] || {})
    i_(svg_(text, svg_attributes), options.except(:svg))
  end

  def spinner(type = :atom, **options)
    div_ '.spinner_container.hidden', options do
      case type
      when :atom
        div_ '.atom-spinner' do
          div_'.spinner-inner', [
            div_('.spinner-line', times: 3),
            div_('.spinner-circle', '&#9679;'.html_safe)
          ]
        end
      when :breeding_rhombus
        div_ '.breeding-rhombus-spinner', [
          (1..8).map{ |i| div_ ".rhombus.child-#{i}" },
          div_('.rhombus.big')
        ]
      when :circles_to_rhombuses
        div_ '.circles-to-rhombuses-spinner' do
          div_ '.circle', times: spinner_variable(type)
        end
      when :fingerprint
        div_ '.fingerprint-spinner' do
          div_ '.spinner-ring', times: 9
        end
      when :fulfilling_bouncing_circle
        div_ '.fulfilling-bouncing-circle-spinner', [
          div_('.circle'),
          div_('.orbit')
        ]
      when :fulfilling_square
        div_ '.fulfilling-square-spinner' do
          div_ '.spinner-inner'
        end
      when :half_circle
        div_ '.half-circle-spinner', [
          div_('.circle.circle-1'),
          div_('.circle.circle-2')
        ]
      when :hollow_dots
        div_ '.hollow-dots-spinner' do
          div_ '.dot', times: spinner_variable(type)
        end
      when :intersecting_circles
        div_ '.intersecting-circles-spinner' do
          div_ '.spinnerBlock' do
            span_ '.circle', times: 7
          end
        end
      when :looping_rhombuses
        div_ '.looping-rhombuses-spinner' do
          div_ '.rhombus', times: 3
        end
      when :orbit
        div_ '.orbit-spinner', [
          div_('.orbit.one'),
          div_('.orbit.two'),
          div_('.orbit.three'),
        ]
      when :radar
        div_ '.radar-spinner' do
          div_('.circle', times: 4) do
            div_ '.circle-inner-container' do
              div_ '.circle-inner'
            end
          end
        end
      when :scaling_squares
        div_ '.scaling-squares-spinner' do
          (1..4).map{ |i| div_ ".square.square-#{i}" }
        end
      when :self_building_square
        div_ '.self-building-square-spinner', [
          div_('.square'),
          (1..8).map{ |i| div_ '.square', class: ('clear' if i % 3 == 0) }
        ]
      when :semipolar
        div_ '.semipolar-spinner' do
          div_ '.ring', times: 5
        end
      when :swapping_squares
        div_ '.swapping-squares-spinner' do
          (1..4).map{ |i| div_ ".square.square-#{i}" }
        end
      when :trinity_rings
        div_ '.trinity-rings-spinner' do
          (1..3).map{ |i| div_ ".circle.circle#{i}" }
        end
      else
        raise "unknown spinner [#{type}]"
      end
    end
  end

  private

  def spinner_variable(type)
    (@@_spinner_variable ||= {})[type] ||= begin
      match = nil
      %W(application.scss stylesheets/_variables.scss vendor/epic-spinners/stylesheets/_#{type}_spinner.scss).find do |path|
        next unless (scss = Pathname.new("app/javascript/#{path}")).exist?
        next unless (scss = scss.read.match(/^\$spinner_#{type}:\s*(\d+)(?:\s*!default)?\s*;\s*$/))
        match = scss[1].to_i
      end
      match || raise("can't find scss variable $spinner_#{type}")
    end
  end
end
