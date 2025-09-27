MonkeyPatch.add{['actionview', 'lib/action_view/helpers/form_tag_helper.rb', '11b737f1893be2188ab7efd2da190490275979e54a3356495cd9a66e126924cc']}

class Object
  def no_space?
    html_safe?
  end
end

class NilClass
  def no_space?
    true
  end
end

class Numeric
  def no_space?
    false
  end
end

class String
  def no_space?
    blank? || super
  end
end

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

  def method_missing(name, *, &)
    if name.end_with? '_'
      tag = name.to_s.delete_suffix('_')
      unless HTML5_TAGS.include? tag
        Rails.logger.info "Tag <#{tag}> isn't HTML5"
      end
      self.class.define_method(name) do |*args, &block|
        with_tag tag, *args, &block
      end
      send(name, *, &)
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
        args.flatten.each do |value|
          concat value
          concat ' ' unless value.no_space?
        end
      end
    end
  end
  alias_method :h_, :capture

  def if_(is_true, *values, &block)
    @_if ||= is_true
    return unless continue(if: is_true)
    h_(*values, &block)
  end

  def elsif_(is_true, *, &)
    raise 'must call "if_" before' unless defined? @_if
    if_(!@_if && is_true, *, &)
  end

  def else_(*, &)
    raise 'must call "if_" before' unless defined? @_if
    if_(!@_if, *, &)
  ensure
    remove_ivar(:@_if)
  end

  def unless_(is_false, *values, &block)
    return unless continue(unless: is_false)
    h_(*values, &block)
  end

  def with_tag(tag, css_or_content_or_options = nil, content_or_options = nil, options_or_content = nil, &block)
    tag = tag&.to_s
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
    options = (options ? options.dup : {}).to_hwka

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
    sanitized = options.delete(:sanitize){ false }
    escape = options.delete(:escape){ true }
    times = options.delete(:times)
    content = options.delete(:text) if options.has_key? :text
    form_before(options) if tag == 'form'
    content = h_(&content) if content.is_a? Proc
    content = h_(&block) if content.nil? && block_given?
    tag_options_content = "#{tag}_options_content"
    content = send(tag_options_content, options, content) if respond_to? tag_options_content, true
    content = h_(content) if content.is_a? Array
    content = sanitize(content) if sanitized
    form_after if tag == 'form'
    before = options.delete(:prepend){ ''.html_safe }
    after  = options.delete(:append){ ''.html_safe }
    result = tag ? content_tag(tag, content, options, (sanitized ? false : escape)) : h_(content)
    result = before << result << after
    result = [result] * times if times
    result
  end

  def merge_classes(options, classes)
    if options.has_key? :class
      old_array = classes_to_array(options[:class])
      new_array = classes_to_array(classes)
      (old_array | new_array).compact_blank
    else
      classes_to_array(classes).compact_blank
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
    when Array, Set
      classes
    else
      classes.to_s.split
    end
  end

  def classes_to_string(classes)
    case classes
    when Hash
      classes.select_map{ |value, condition| value if condition }.join(' ')
    when Array, Set
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
    options['data-turbolinks'] = options.delete(:turbolinks)
    set_data_remote(options)
    content
  end

  def button_options_content(options, content)
    options[:type] ||= 'submit'
    content
  end

  def form_before(options)
    if (as = options.delete(:as)).respond_to? :model_name
      @_form_as = as.model_name.param_key
      @_form = as
    elsif as
      @_form_as = as
      @_form = ivar("@#{as}")
    end
  end

  def form_options_content(options, content)
    options.replace html_options_for_form(options.delete(:action) || '', options)
    options['data-visit'] = options.delete(:visit)
    tags = extra_tags_for_form(options).html_safe
    unless options.delete(:timezone) == false || options[:method] == 'get' || ExtRails.config.css_only_support
      timezone_tag = input_(type: 'hidden', name: '_timezone', value: Current.timezone.to_s)
      tags = tags.present? ? tags + timezone_tag : timezone_tag
    end
    if @_form
      action = @_form.persisted? ? :edit : :new
      options[:id] ||= dom_id(@_form, action)
      options[:class] = merge_classes(options, dom_class(@_form, action))
    end
    options[:role] ||= 'form'
    tags += input_(type: 'hidden', name: '_back', value: back_path) if options.delete(:back)
    [tags, content]
  end

  def form_after
    remove_ivar(:@_form_as)
    remove_ivar(:@_form)
  end

  def label_options_content(options, content)
    id = options[:for]
    as = "#{@_form_as}_" if @_form_as && options.delete(:as) != false
    if as && id && !id.start_with?(as)
      id = "#{as}#{id}"
    end
    options[:for] = sanitize_to_id(id) if id.present?
    content
  end

  def input_options_content(options, content)
    object, name = set_object_name_and_id(options)
    options[:'aria-label'] ||= options[:placeholder]
    case options[:type].to_s
    when 'submit'
      skip_value = true
      options[:name] ||= 'commit'
      set_default_disable_with(options[:value], options) if options[:value].present?
    when 'checkbox'
      if (skip_value = options.delete(:include_hidden))
        value = if options.has_key? :value
          options[:value]
        elsif object && name
          object.public_send(name)
        else
          return content
        end.to_b
        options[:value] = 1
        options[:checked] = value
        options[:prepend] = input_ type: 'hidden', value: 0, id: nil, **options.slice(:name, :disabled)
      end
    when 'hidden'
      options[:autocomplete] ||= 'off'
    end
    if !skip_value && !options.has_key?(:value) && object && name && !name.start_with?('password')
      options[:value] = object.public_send(name)
    end
    content
  end

  def select_options_content(options, content)
    set_object_name_and_id(options)
    content
  end

  def textarea_options_content(options, content)
    set_object_name_and_id(options)
    content
  end

  def set_object_name_and_id(options)
    name = options[:name]
    if name
      as = "#{@_form_as}[" if @_form_as && options.delete(:as) != false
      if as && !name.start_with?('_', as)
        if (through = options.delete(:through))
          as = "#{as}#{through}_attributes]["
        end
        object = @_form
        options[:name] = "#{as}#{name}]"
      end
      if options[:multiple] == true && !name.end_with?('[]')
        options[:name] = "#{options[:name]}[]"
      end
    end
    unless options.has_key? :id
      id = options[:id].presence || options[:name]
      options[:id] = sanitize_to_id(id) if id.present?
    end
    set_data_remote(options)
    [object, name]
  end

  def set_data_remote(options)
    return unless options.delete(:remote)
    options['data-remote'] = true
    options['data-method'] = options.delete(:method)
    options['data-url'] = options.delete(:url)
    options['data-params'] = case (params = options.delete(:params))
      when Hash, Array then params.to_query
      else params
      end
    options['data-visit'] = options.delete(:visit)
  end
end
