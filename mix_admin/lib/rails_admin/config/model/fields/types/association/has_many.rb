class RailsAdmin::Config::Model::Fields::Association::HasMany < RailsAdmin::Config::Model::Fields::Association
  # orderable associated objects
  register_instance_option :orderable do
    false
  end

  register_instance_option :scope do
    nil
  end

  def multiple?
    true
  end

  def value
    result = object.send(property.name)
    result = result.send(scope) if scope
    result
  end

  def method_name
    nested_options ? "#{super}_attributes".to_sym : "#{super.to_s.singularize}_ids".to_sym # name_ids
  end

  # Reader for validation errors of the bound object
  def errors
    object.errors[name]
  end

  def render_nested
    model = associated_model
    abstract_model = model.abstract_model
    selected = selected_objects(abstract_model)
    can_create, can_destroy = !nested_options[:update_only], nested_options[:allow_destroy]
    errors_index = selected.find_index{ |object| object.errors.any? }
    opened = active? || errors_index
    association_id = form.nested_form_dom_id(name)

    div_('.js_nested_form_wrapper', [
      div_('.controls.col-sm-10', [
        div_('.btn-group', [
          a_(".btn.btn-#{errors_index ? 'danger' : 'info'}.js_nested_form_toggle#{'.active' if opened}#{'.js_disable' if selected.empty?}", href: '#') do
            i_ ".fa.fa-chevron-#{opened ? 'down' : 'right'}.icon-white"
          end,
          if can_create && inline_add
            form.link_to_add(name, class: 'btn btn-info') {[
              i_('.fa.fa-plus.icon-white'),
              wording_for(:link, :new, abstract_model)
            ]}
          end
        ]),
        form.errors_for(self),
        form.help_for(self),
        ul_(".nav.nav-tabs", class: ('soft_hidden' unless opened)) do
          selected.map.with_index do |object, i|
            li_ class: [('active' if i == errors_index), ('has-error' if object.errors.any?)].compact do
              a_ href: "#tab_#{association_id}_#{i}", data: { toggle: 'tab' } do
                model.with(object: object).object_label
              end
            end
          end
        end,
      ]),
      div_(".tab-content", class: ('soft_hidden' unless opened)) do
        if selected.empty?
          template_object = object.send(name).build
          form.fields_for name, template_object do |f|
            h_(
              f.link_to_remove(name) do
                f.span_ ".btn.btn-sm.btn-default", f.i_('.fa.fa-trash-o')
              end,
              f.generate(section: :nested, model: associated_model, nested_in: self)
            )
          end
        end
        selected.map.with_index do |object, i|
          div_ "#tab_#{association_id}_#{i}.tab-pane.fade#{'.active.in' if i == errors_index}" do
            form.fields_for name, object do |f|
              h_(
                if (is_template = f.options[:nested_form_template] || object.new_record?) || can_destroy
                  f.link_to_remove name do
                    f.span_ ".btn.btn-sm.btn-#{is_template ? 'default' : 'danger'}", f.i_('.fa.fa-trash-o')
                  end
                end,
                f.generate(section: :nested, model: model, nested_in: self)
              )
            end
          end
        end
      end
    ])
  end

  def render_filtering
    collection, selected_ids, new_params, abstract_model, config = filtering_options
    field_id = form.dom_id(self)
    h_(
      div_(class: bs_form_row) do
        form.select(method_name, collection, { include_blank: include_blank?, selected: selected_ids, object: form.object },
          html_attributes.reverse_merge(
            class: 'form-control js_field_input',
            data: { element: 'select_multi_remote', config: config },
            multiple: true,
          )
        )
      end,
      ul_('.list-inline', [
        # TODO config for chose_all?, reset?, clear_all?
        # TODO auto focus on input after token entered for reopening select box
        # li_('.icon', title: t("admin.concepts.select.chose_all")) do
        #   a_('.btn.btn-default.btn-sm.js_select_multi_chose_all', { href: '#', data: { id: field_id } }, [
        #     i_('.fa.fa-check'),
        #     t("admin.concepts.select.chose_all")
        #   ])
        # end,
        # li_('.icon', title: t("admin.concepts.select.reset")) do
        #   a_('.btn.btn-default.btn-sm.js_select_multi_reset', { href: '#', data: { id: field_id } }, [
        #     i_('.fa.fa-undo'),
        #     t("admin.concepts.select.reset")
        #   ])
        # end,
        # if removable
        #   li_ '.icon', title: t("admin.concepts.select.clear_all") do
        #     a_('.btn.btn-default.btn-sm.js_select_multi_clear_all', { href: '#', data: { id: field_id } }, [
        #       i_('.fa.fa-times'),
        #       t("admin.concepts.select.clear_all")
        #     ])
        #   end
        # end,
        if new_params
          li_ '.icon', title: wording_for(:link, :new, abstract_model) do
            a_ '.js_modal_form_new.btn.btn-default.btn-sm', i_('.fa.fa-plus'),
              href: '#',
              data: { new: { params: new_params, select_id: field_id } }
          end
        end
      ]),
    )
  end

  def filtering_options
    model = associated_model
    abstract_model = model.abstract_model

    selected = selected_objects(abstract_model)
    selected_ids = selected.map{|s| s.send(associated_primary_key)}

    modal = request.variant.modal?

    if authorized?(:edit, abstract_model) && inline_edit && !modal
      edit_params = { model_name: abstract_model.to_param, modal: true }
    end

    config = {
      edit_params: edit_params,
      sortable: !!orderable,
      removable: !!removable,
      index_params: { # TODO frontend not working
        model_name: abstract_model.to_param,
        compact: true
      },
      required: required?,
      include_blank: include_blank?,
    }

    if authorized?(:new, abstract_model) && inline_add && !modal
      new_params = { model_name: abstract_model.to_param, modal: true }
      new_params.merge!(associations: { inverse_of => (form.object.persisted? ? form.object.id : 'new') }) if inverse_of
    end

    collection = selected.map{ |o| [model.with(object: o).object_label, o.send(associated_primary_key)] }
    selected_ids = (fdv = form_default_value).nil? ? selected_ids : fdv

    [collection, selected_ids, new_params, abstract_model, config]
  end

  def selected_objects(abstract_model)
    related_id = params.dig(:associations, name)

    if form.object.new_record? && related_id.present? && related_id != 'new'
      [abstract_model.get(related_id)]
    else
      form_value.presence || form.object.try("cloned_#{name}") || []
    end
  end
end
