module ExtTailwindHelper
  SVG_BEGIN = /^\s*<svg [^>]+>\s*/
  SVG_END = /\s*<\/svg>\s*$/
  SVG_OUTLINE = { xmlns: 'http://www.w3.org/2000/svg', fill: 'none', viewBox: '0 0 24 24', 'stroke-width': 2, stroke: 'currentColor', 'aria-hidden': true }
  SVG_SOLID = { xmlns: 'http://www.w3.org/2000/svg', viewBox: '0 0 20 20', fill: 'currentColor', 'aria-hidden': true }

  def icon(name, type = :outline, **options)
    type = type.to_sym
    text = ((@@_icon ||= {})[type] ||= {})[name] ||= begin
      Pathname.new("node_modules/heroicons/#{type}/#{name}.svg").read.sub!(SVG_BEGIN, '').sub!(SVG_END, '').html_safe
    end
    case type
    when :outline
      svg_ text, SVG_OUTLINE.merge(options)
    when :solid
      svg_ text, SVG_SOLID.merge(options)
    end
  end
end
