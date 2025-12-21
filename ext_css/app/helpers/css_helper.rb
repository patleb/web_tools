module CssHelper
  SVG_BEGIN = /^\s*<svg [^>]+>\s*/
  SVG_END = /\s*<\/svg>\s*$/
  SVG_OPTIONS = { xmlns: 'http://www.w3.org/2000/svg', fill: 'currentColor', height: 16, width: 16, viewBox: '0 0 16 16', 'aria-hidden': true }

  def preload_icons
    @@_preload_icons ||= begin
      lines = Pathname.new("node_modules/bootstrap-icons/font/bootstrap-icons.css").readlines
      line = lines.find{ |line| line.include? 'fonts/bootstrap-icons.woff2' }
      id = line.match(%r{fonts/bootstrap-icons\.woff2\?([^"]+)}).captures.first
      url = "static/node_modules/bootstrap-icons/font/fonts/bootstrap-icons.woff2?#{id}"
      preload_pack_asset(url, as: :font, type: 'font/woff2', crossorigin: true)
    end
  end

  def preload_fonts
    @@_preload_fonts ||= %w(roman italic).map do |style|
      url = "static/vendor/tailwindcss-rails/fonts/Inter-#{style}.latin.var.woff2"
      preload_pack_asset(url, as: :font, type: 'font/woff2', crossorigin: true)
    end
  end

  def icon_(...)
    html = icon(...)
    html << ' '.html_safe if html
  end

  def _icon(...)
    html = icon(...)
    ' '.html_safe << html if html
  end

  def _icon_(...)
    html = icon(...)
    ' '.html_safe << html << ' '.html_safe if html
  end

  # https://icons.getbootstrap.com/
  def icon(name, tag: nil, svg: {}, **options)
    return unless continue(options)
    name, *classes = name.to_s.split('.')
    name = name.dasherize
    options[:class] = merge_classes(options, classes)
    text = (@@_icon ||= {})[name] ||= begin
      Pathname.new("node_modules/bootstrap-icons/icons/#{name}.svg").read.sub!(SVG_BEGIN, '').sub!(SVG_END, '').html_safe
    end
    svg_options = SVG_OPTIONS.merge(svg)
    case tag
    when false
      svg_(text, svg_options)
    when nil
      i_(svg_(text, svg_options), options)
    else
      with_tag(tag, svg_(text, svg_options), options)
    end
  end

  def ascii_(...)
    html = ascii(...)
    html << ' '.html_safe if html
  end

  def _ascii(...)
    html = ascii(...)
    ' '.html_safe << html if html
  end

  def _ascii_(...)
    html = ascii(...)
    ' '.html_safe << html << ' '.html_safe if html
  end

  def ascii(name, times: nil)
    return if times == 0
    @@_ascii ||= {
      space:            'nbsp',
      hyphen:           '#8209',  # -
      dash:             'ndash',  # –
      copyright:        'copy',   # ©
      registered:       'reg',    # ®
      trademark:        'trade',  # ™
      arrow_left:       'larr',   # ←
      arrow_left_x2:    'laquo',  # «
      arrow_right:      'rarr',   # →
      arrow_right_x2:   'raquo',  # »
      arrow_up:         'uarr',   # ↑
      arrow_up_left:    'lsh',    # ↰
      arrow_up_right:   'rsh',    # ↱
      arrow_down:       'darr',   # ↓
      arrow_down_left:  'ldsh',   # ↲
      arrow_down_right: 'rdsh',   # ↳
      arrow_x:          'harr',   # ↔
      arrow_y:          'varr',   # ↕
      triangle_up:      '#9651',  # △
      triangle_down:    '#9661',  # ▽
      degree:           'deg',    # °
      degree_c:         '#8451',  # ℃
      degree_f:         '#8457',  # ℉
      micro:            'micro',  # µ
      plus_minus:       'plusmn', # ±
      plus:             'plus',   # +
      minus:            'minus',  # −
      multiply:         'times',  # ×
      x:                'times',  # ×
      divide:           'divide', # ÷
      equal:            'equals', # =
      approx:           'asymp',  # ≈
      not_equal:        'ne',     # ≠
      greater:          'gt',     # >
      less:             'lt',     # <
      greater_or_equal: '#8805',  # ≥
      less_or_equal:    '#8804',  # ≤
      squared:          'sup2',   # ²
      cubed:            'sup3',   # ³
      quarter:          'frac14', # ¼
      half:             'frac12', # ½
      three_quarters:   'frac34', # ¾
      bullet:           '#8226',  # •
      ellipsis:         '#8230',  # …
      check:            'check',  # ✓
      cross:            'cross',  # ✗
    }
    code = @@_ascii[name.to_sym] || raise("unsupported ascii name '#{name}'")
    code = "&#{code};"
    code = code * times if times
    code.html_safe
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
      (ExtCss.config.variables + ["vendor/epic-spinners/stylesheets/#{type}_spinner.css"]).find do |path|
        next unless (css = Pathname.new("app/javascript/#{path}")).exist?
        next unless (css = css.read.match(/^\s*--spinner_#{type}\s*:\s*(\d+)\s*;/))
        match = css[1].to_i
      end
      [match, 9].min.presence || raise("can't find css variable --spinner_#{type}")
    end
  end
end
