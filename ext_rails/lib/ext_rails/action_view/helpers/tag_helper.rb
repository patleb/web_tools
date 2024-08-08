# frozen_string_literal: true

module ActionView::Helpers::TagHelper
  HTML5_TAGS = Set.new(%w(
    a abbr address area article aside audio
    b base bdi bdo blockquote body br button
    canvas caption cite code col colgroup
    data datalist dd del details dfn dialog div dl dt
    em embed
    fieldset figcaption figure footer form
    h1 h2 h3 h4 h5 h6 head header hgroup hr html
    i iframe img input ins
    kbd keygen
    label legend li link
    main map mark menu menuitem meta meter
    nav noscript
    object ol optgroup option output
    p param picture pre progress
    q
    rp rt ruby
    s samp script section select small source span strong style sub summary sup svg
    table tbody td template textarea tfoot th thead time title tr track
    u ul
    var video
    wbr
  ))
  ID_CLASSES = /^([#.][A-Za-z_-][:\w-]*)+$/.freeze

  def html_(*args, &block)
    h_(
      '<!DOCTYPE html>'.html_safe,
      with_tag('html', *args, &block)
    )
  end

  def method_missing(name, *args, &block)
    if name.end_with? '_'
      tag = name.to_s.delete_suffix('_')
      unless HTML5_TAGS.include? tag
        Rails.logger.info "Tag <#{tag}> isn't HTML5"
      end
      self.class.send(:define_method, name) do |*args, &block|
        with_tag tag, *args, &block
      end
      send(name, *args, &block)
    else
      super
    end
  end

  def respond_to_missing?(name, _include_private = false)
    name.end_with?('_') || super
  end

  def capture(*args)
    if block_given?
      value = nil
      buffer = with_output_buffer { value = yield(*args) }
      value = buffer.presence || value
      case value
      when String
        ERB::Util.html_escape value
      when Array
        capture(value)
      else
        ERB::Util.html_escape value.to_s
      end
    else
      super() do
        args.flatten.each{ |value| concat value }
      end
    end
  end
  alias_method :h_, :capture

  def h_if(is_true, *values, &block)
    return unless continue(if: is_true)
    h_(*values, &block)
  end

  def h_unless(is_false, *values, &block)
    return unless continue(unless: is_false)
    h_(*values, &block)
  end

  def with_tag(tag, css_or_content_or_options = nil, content_or_options = nil, options_or_content = nil, &block)
    tag = tag.to_s
    unless css_or_content_or_options.nil?
      case css_or_content_or_options
      when ID_CLASSES
        id_classes = css_or_content_or_options
        unless content_or_options.nil?
          case content_or_options
          when Hash
            content = options_or_content
            options = content_or_options
          else
            content = content_or_options
            options = options_or_content
          end
        end
      when Hash
        content = content_or_options
        options = css_or_content_or_options
      else
        content = css_or_content_or_options
        options = content_or_options if content_or_options.is_a? Hash
      end
    end
    options = options ? options.dup : {}

    return unless continue(options)

    if id_classes
      id, classes = parse_id_classes(id_classes)
      options[:id] ||= id
      options[:class] = merge_classes(options, classes)
    end
    if (classes = options[:class])
      options[:class] = classes_to_string(classes)
      options.delete(:class) if options[:class].blank?
    end
    sanitized = options.has_key?(:sanitize) ? options.delete(:sanitize) : false
    escape = options.has_key?(:escape) ? options.delete(:escape) : true
    times = options.delete(:times) if options.has_key? :times
    content = options.delete(:text) if options.has_key? :text
    content = h_(&content) if content.is_a? Proc
    content = h_(&block) if content.nil? && block_given?
    tag_options_content = "#{tag}_options_content"
    content = send(tag_options_content, options, content) if respond_to? tag_options_content
    content = h_(content) if content.is_a? Array
    content = sanitize(content) if sanitized

    result = content_tag tag, content, options, (sanitized ? false : escape)
    result = [result] * times if times
    result
  end

  def extra_tags_for_form(html_options)
    tags = super
    return tags if html_options.delete('timezone') == false || html_options['method'] == 'get'
    return tags unless ExtRails.config.css_only_support?
    timezone_tag = input_(type: 'hidden', name: '_timezone', value: Current.timezone.to_s)
    tags.present? ? tags + timezone_tag : timezone_tag
  end

  def merge_classes(options, classes)
    if options.has_key? :class
      old_array = classes_to_array(options[:class])
      new_array = classes_to_array(classes)
      (old_array | new_array).reject(&:blank?)
    else
      classes_to_array(classes).reject(&:blank?)
    end
  end

  private

  def parse_id_classes(string)
    classes, _separator, id_classes = string.partition('#')
    classes = classes.split('.')
    if id_classes
      id, *other_classes = id_classes.split('.')
      classes.concat(other_classes)
    end
    [id, classes]
  end

  def classes_to_array(classes)
    case classes
    when Hash
      classes_to_array(classes.select_map{ |value, condition| value if condition })
    when Array
      classes
    else
      classes.try(:split) || []
    end
  end

  def classes_to_string(classes)
    case classes
    when Hash
      classes.select_map{ |value, condition| value if condition }.join(' ')
    when Array
      classes.compact_blank.join(' ')
    else
      classes
    end
  end

  def continue(options)
    if options.has_key? :if
      is_true = options.delete(:if)
      is_true = is_true.() if is_true.is_a? Proc
      return false unless is_true
    end
    if options.has_key? :unless
      is_true = options.delete(:unless)
      is_true = is_true.() if is_true.is_a? Proc
      return false if is_true
    end
    true
  end

  def a_options_content(options, content)
    options[:rel] = 'noopener' if options[:rel].blank?
    content
  end

  def form_options_content(options, content)
    options = html_options_for_form(options.delete(:action) || '', options)
    [extra_tags_for_form(options), content]
  end

  def label_options_content(options, content)
    id = options[:for]
    options[:for] = sanitize_to_id(id) if id.present?
    content
  end

  def input_options_content(options, content)
    id = options[:id].presence || options[:name]
    options[:id] = sanitize_to_id(id) if id.present?
    content
  end

  def select_options_content(options, content)
    name = options[:name]
    id = options[:id].presence || name
    options[:name] = "#{name}[]" if name.present? && options[:multiple] == true && !name.end_with?("[]")
    options[:id] = sanitize_to_id(id) if id.present?
    content
  end
end
