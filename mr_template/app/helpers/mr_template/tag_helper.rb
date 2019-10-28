module MrTemplate
  module TagHelper
    HTML_TAGS = %i(
      a
      b body button
      dd div dl dt
      em
      fieldset
      h1 h2 h3 h4 h5 h6 head hr html
      i input
      label legend li link
      meta
      nav
      option
      p pre
      script select span strong style
      table tbody td th thead title tr
      ul
    ).freeze

    HTML5_TAGS = Set.new(%i(
      a abbr address area article aside audio
      b base bdo blockquote body br button
      canvas caption cite code col colgroup command
      datalist dd del details dfn div dl dt
      em embed
      fieldset figcaption figure footer form
      h1 h2 h3 h4 h5 h6 head header hgroup hr html
      i iframe img input ins
      keygen kbd
      label legend li link
      map mark menu menuitem meta meter
      nav noscript
      object ol optgroup option output
      p param pre progress
      q
      s samp script section select small source span strong style sub summary sup svg
      table tbody td textarea tfoot th thead time title tr track
      ul
      var video
      wbr
    ))

    ID_CLASSES = /^([#.][A-Za-z_-][A-Za-z0-9_-]*)+$/.freeze

    def self.tags
      @tags ||= begin
        if Rails.env.development?
          MrTemplate.config.html_extra_tags.each do |tag|
            unless HTML5_TAGS.include? tag
              Rails.logger.info "Tag <#{tag}> isn't HTML5"
            end
          end
        end
        HTML_TAGS + MrTemplate.config.html_extra_tags
      end
    end

    tags.each do |tag|
      define_method "#{tag}_" do |*args, &block|
        with_tag tag, *args, &block
      end
    end

    # TODO https://github.com/rails/rails/pull/32125
    def utf8_enforcer_tag
      ''.html_safe
    end

    alias_method :old_html_, :html_
    def html_(*args, &block)
      h_(
        '<!DOCTYPE html>'.html_safe,
        old_html_(*args, &block)
      )
    end

    def capture(*values, &block)
      if block_given?
        # TODO wrap block with a list stacks
        # if within block, push item to queue
        # else if exit block (ensure), join items from queue, then concat
        # --> will allow syntax without arrays
        if values.any?
          super
        else
          value = nil
          buffer = with_output_buffer { value = yield }
          value = buffer.presence || value
          case value
          when String
            ERB::Util.html_escape value
          when Array
            capture(value)
          else
            ERB::Util.html_escape value.to_s
          end
        end
      else
        super() do
          values.flatten.each do |value|
            concat value
            concat ' ' unless value.blank? || value.no_space?
          end
        end
      end
    end
    alias_method :h_, :capture

    def h_if(is_true, *values, &block)
      return '' unless continue(if: is_true)
      h_(*values, &block)
    end

    def h_unless(is_false, *values, &block)
      return '' unless continue(unless: is_false)
      h_(*values, &block)
    end

    def with_tag(tag, css_or_text_or_options = nil, text_or_options = nil, options_or_text = nil, &block)
      unless css_or_text_or_options.nil?
        case css_or_text_or_options
        when ID_CLASSES
          id_classes = css_or_text_or_options
          unless text_or_options.nil?
            case text_or_options
            when Hash
              text = options_or_text
              options = text_or_options
            else
              text = text_or_options
              options = options_or_text
            end
          end
        when Hash
          text = text_or_options
          options = css_or_text_or_options
        else
          text = css_or_text_or_options
          options = text_or_options
        end
      end
      options = options ? options.dup : {}

      return '' unless continue(options)

      if id_classes
        id, classes = parse_id_classes(id_classes)
        options[:id] ||= id
        options = merge_classes(options, classes)
      end

      if options[:class].is_a? Array
        options[:class] = options[:class].select(&:present?).join(' ')
        options.delete(:class) if options[:class].blank?
      end

      escape = options.has_key?(:escape) ? options.delete(:escape) : true
      times = options.delete(:times) if options.has_key? :times
      text = options.delete(:text) if options.has_key? :text
      text = h_(&text) if text.is_a? Proc
      text = h_(&block) if text.nil? && block_given?
      text = h_(text) if text.is_a? Array

      result = content_tag tag, text, options, escape
      result = [result] * times if times
      result
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

    def merge_classes(options, classes)
      if options.has_key? :class
        options.merge(class: classes) do |_key, old_val, new_val|
          old_array = classes_to_array(old_val)
          new_array = classes_to_array(new_val)
          (old_array | new_array).reject(&:blank?)
        end
      else
        options[:class] = classes_to_array(classes).reject(&:blank?)
        options
      end
    end

    def classes_to_array(classes)
      (classes.is_a?(Array) ? classes : classes.try(:split) || [])
    end

    def continue(options)
      unless (is_true = options.delete(:if)).nil?
        is_true = is_true.() if is_true.is_a? Proc
        return false unless is_true
      end
      unless (is_true = options.delete(:unless)).nil?
        is_true = is_true.() if is_true.is_a? Proc
        return false if is_true
      end
      true
    end
  end
end
