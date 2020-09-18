module RailsAdmin
  class FormBuilder < ::ActionView::Helpers::FormBuilder
    def generate(section: main_action.to_sym, nested_in: false, model: self.model)
      without_field_error_proc_added_div do
        h_(
          visible_groups(model, generator_section(section, nested_in)).map do |group|
            fieldset_for group, nested_in
          end,
          unless nested_in
            div_ '.form-group.form-actions', class: ('hidden' if request.variant.modal?) do
              div_('.col-sm-offset-2.col-sm-10', [
                hidden_field_tag(:_back, redirect_to_back?),
                if model.save_label?
                  button_('.btn.btn-primary', { class: bs_form_row, type: "submit", name: "_save", data: { disable: :submit } }, [
                    i_('.fa.fa-check.icon-white'),
                    model.save_label
                  ])
                end,
                if model.save_and_add_another_label? && authorized?(:new, abstract_model)
                  button_('.btn.btn-info', class: bs_form_row, type: "submit", name: "_add_another", data: { disable: :submit }) do
                    model.save_and_add_another_label
                  end
                end,
                if model.save_and_edit_label? && authorized?(:edit, abstract_model)
                  button_('.btn.btn-info', class: bs_form_row, type: "submit", name: "_add_edit", data: { disable: :submit }) do
                    model.save_and_edit_label
                  end
                end,
                if model.cancel_label?
                  button_('.btn.btn-default', { class: bs_form_row, type: "submit", name: "_cancel", data: { disable: :submit }, formnovalidate: true }, [
                    i_('.fa.fa-times'),
                    model.cancel_label
                  ])
                end
              ])
            end
          end
        )
      end
    end

    def fieldset_for(group, nested_in)
      return if (fields = group.visible_fields).empty?

      nested_in.bindings = { form: self, object: @object } if nested_in && nested_in.bindings.nil?

      fieldset_ [
        legend_({class: group.name == :default ? 'hidden' : 'js_main_panel'}, [
          i_(".fa.fa-chevron-#{(group.active? ? 'down' : 'right')}"),
          group.label
        ]),
        if group.help.present?
          p_(group.help)
        end,
        fields.map{ |field| field_wrapper_for(field, nested_in) }
      ]
    end

    def field_wrapper_for(field, nested_in)
      if field.label
        # do not show nested field if the target is the origin
        unless nested_field_association?(field, nested_in)
          div_({ class: field.css_classes(:form), id: "#{dom_id(field)}_field" }, [
            label(field.method_name, field.label.upcase_first, class: 'col-sm-2 control-label'),
            (field.nested_options ? field_for(field) : input_for(field))
          ])
        end
      else
        field.nested_options ? field_for(field) : input_for(field)
      end
    end

    def input_for(field)
      css = "#{'col-sm-10 controls' unless field.type == :hidden} #{'has-error' if field.errors.present?}"
      div_(class: css) do
        field_for(field) + errors_for(field) + help_for(field)
      end
    end

    def errors_for(field)
      field.errors.present? ? span_('.help-inline.text-danger', field.errors.to_sentence) : ''.html_safe
    end

    def help_for(field)
      field.help.present? ? span_('.help-block.col-sm-10', simple_format(field.help)) : ''.html_safe
    end

    def field_for(field)
      field.readonly? ? div_('.form-control-static', field.pretty_value_or_blank) : field.render
    end

    def object_label
      model = RailsAdmin.model(object)
      model_label = model.label
      if object.new_record?
        I18n.t('admin.form.new_model', name: model_label)
      else
        object.send(model.object_label_method).presence || "#{model.label} ##{object.id}"
      end
    end

    def dom_id(field)
      (@dom_id ||= {})[field.name] ||= [
        @object_name.to_s.gsub(/\]\[|[^-a-zA-Z0-9:.]/, '_').sub(/_$/, ''),
        options[:index],
        field.method_name,
      ].reject(&:blank?).join('_')
    end

    # TODO https://www.driftingruby.com/episodes/nested-forms-from-scratch-with-stimulusjs
    def link_to_add(text, association = nil, html_options = nil, &block)
      html_options, association, text = association, text, h_(&block) if block_given?

      unless object.respond_to?("#{association}_attributes=")
        raise ArgumentError, "Invalid association. Make sure that accepts_nested_attributes_for is used for #{association.inspect} association."
      end

      html_options ||= {}
      association_id = nested_form_dom_id(association)
      html_options.symbolize_keys!
      html_options[:class] ||= []
      html_options[:class] << " js_nested_form_add"
      html_options[:data] ||= {}
      html_options[:data][:association] = { id: association_id }
      html_options[:href] ||= '#'
      association_model = RailsAdmin.model(object.class.reflect_on_association(association).klass)

      after_nested_form(association_id) do
        block, options = @nested_form_fields[association_id]
        options[:child_index] = "js_nested_form_child_#{association_id}"
        options[:nested_form_template] = true
        template = fields_for(association, association_model.abstract_model.new, options, &block)
        div_ "#js_nested_form_template_#{association_id}.js_base_template",
          data: { form: { template: template, object_label: I18n.t('admin.form.new_model', name: association_model.label) } }
      end
      link_to(text, nil, html_options)
    end

    def link_to_remove(text, association = nil, html_options = nil, &block)
      html_options, association, text = association, text, h_(&block) if block_given?

      html_options ||= {}
      html_options[:class] ||= []
      html_options[:class] << " js_nested_form_remove"
      html_options[:data] ||= {}
      html_options[:data][:association] = { id: nested_form_dom_id(association) }
      html_options[:href] ||= '#'

      hidden_field(:_destroy) << link_to(text, nil, html_options)
    end

    def nested_form_dom_id(association)
      (@nested_form_dom_id ||= {})[association] ||= begin
        assocs = object_name.to_s.scan(/(\w+)_attributes/).map(&:first)
        assocs << association
        assocs.join('_')
      end
    end

    def abstract_model
      Current.view.instance_variable_get(:@abstract_model)
    end

    def model
      Current.view.instance_variable_get(:@model)
    end

    def method_missing(name, *args, &block)
      if Current.view.respond_to? name
        Current.view.public_send(name, *args, &block)
      elsif Current.controller.respond_to? name, true
        Current.controller.__send__(name, *args, &block)
      else
        raise NoMethodError.new("No method '#{name}' for #{self.class} or Current.view or Current.controller", name)
      end
    end

    def respond_to_missing?(name, include_private = false)
      @_locals.has_key?(name) || Current.view.respond_to?(name, include_private) || Current.controller.respond_to?(name, true)
    end

    protected

    def generator_section(section, nested)
      if nested
        section = :nested
      elsif request.variant.modal?
        section = :modal
      end
      section
    end

    def visible_groups(model, section)
      model.send(section).with(form: self, object: @object).visible_groups
    end

    def without_field_error_proc_added_div
      default_field_error_proc = ::ActionView::Base.field_error_proc
      begin
        ::ActionView::Base.field_error_proc = proc { |html_tag, _instance| html_tag }
        yield
      ensure
        ::ActionView::Base.field_error_proc = default_field_error_proc
      end
    end

    private

    def nested_field_association?(field, nested_in)
      field.inverse_of.presence && nested_in.presence && field.inverse_of == nested_in.name \
      && (model.abstract_model == field.abstract_model || field.name == nested_in.inverse_of)
    end

    def fields_for_with_nested_attributes(association_name, association, options, block)
      @nested_form_fields ||= {}
      @nested_form_fields[nested_form_dom_id(association_name)] = [block, options]
      super(association_name, association, options, block)
    end
  end
end
