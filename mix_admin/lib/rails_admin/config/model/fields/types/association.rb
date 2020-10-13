class RailsAdmin::Config::Model::Fields::Association < RailsAdmin::Config::Model::Fields::Base
  autoload_dir RailsAdmin::Engine.root.join('lib/rails_admin/config/model/fields/types/association')

  delegate :foreign_key, :polymorphic?, to: :property

  register_instance_option :pretty_value do
    safe_join(pretty_association, association_separator)
  end

  register_instance_option :index_value do
    if truncated?
      truncated_association
    else
      pretty_value
    end
  end

  register_instance_option :truncated?, memoize: true do
    true
  end

  def association_separator
    @association_separator ||= '<br>'.html_safe
  end

  def pretty_association
    [value].flatten.select(&:present?).map do |associated|
      model = polymorphic? ? RailsAdmin.model(associated) : associated_model # perf optimization for non-polymorphic associations
      wording = model.with(object: associated).object_label
      wording = sanitize(wording) if sanitized?
      if associated.try(:discarded?)
        path = authorized_path_for(:trash, model)
      else
        path = authorized_path_for(:show, model, associated) || authorized_path_for(:edit, model, associated)
      end
      path ? a_('.pjax', wording, href: path) : ERB::Util.html_escape(wording)
    end
  end

  def truncated_association(value = pretty_value)
    return value unless value.present?
    return value unless (length = value.index(association_separator))
    options = truncated_value_options.merge!(length: length, separator: association_separator, escape: false)
    truncated_value(value, options)
  end

  def visible_association?
    associated_model.visible? && visible_field?
  end

  # Accessor whether association is visible or not. By default
  # association checks whether the child model is excluded in
  # configuration or not.
  register_instance_option :visible? do
    visible_association?
  end

  # use the association name as a key, not the association key anymore!
  register_instance_option :label, memoize: :locale do
    klass.human_attribute_name(property.name)
  end

  # inverse relationship
  register_instance_option :inverse_of do
    property.inverse_of
  end

  # determines whether association's elements can be removed
  register_instance_option :removable? do
    !property.required?
  end

  register_instance_option :inline_add do
    true
  end

  register_instance_option :inline_edit do
    true
  end

  register_instance_option :eager_load? do
    true
  end

  register_instance_option :left_joins? do
    false
  end

  register_instance_option :distinct? do
    false
  end

  register_instance_option :render do
    nested_options ? render_nested : render_filtering
  end

  # Reader for nested attributes
  register_instance_option :nested_options do
    property.nested_options
  end

  register_instance_option :include_blank?, memoize: :locale do
    true
  end

  def association?
    true
  end

  # Reader for the association's child model's configuration
  def associated_model
    @associated_model ||= RailsAdmin.model(property.klass)
  end

  # Reader for associated primary key
  def associated_primary_key
    @associated_primary_key ||= property.primary_key
  end

  # Reader for the association's value unformatted
  def value
    object.send(property.name)
  end

  def multiple?
    false
  end

  def virtual?
    true
  end

  def render_nested
    model = associated_model
    abstract_model = model.abstract_model
    selected = selected_object(abstract_model) || form.object.send(name)
    can_create, can_destroy = !nested_options[:update_only], nested_options[:allow_destroy]
    with_errors = selected&.errors&.any?
    opened = active? || with_errors
    association_id = form.nested_form_dom_id(name)

    div_('.js_nested_form_wrapper', [
      div_('.controls.col-sm-10', [
        div_('.btn-group', [
          a_(".btn.btn-#{with_errors ? 'danger' : 'info'}.js_nested_form_toggle#{'.js_nested_form_last_button' if selected}#{'.active' if opened}#{'.js_disable' unless selected}", href: '#') do
            i_ ".fa.fa-chevron-#{opened ? 'down' : 'right'}.icon-white"
          end,
          if can_create && inline_add
            form.link_to_add(name, class: "btn btn-info js_nested_form_one #{'soft_hidden' if selected}") {[
              i_('.fa.fa-plus.icon-white'),
              wording_for(:link, :new, associated_model.abstract_model)
            ]}
          end
        ]),
        form.errors_for(self),
        form.help_for(self),
        ul_(".nav.nav-tabs.hidden") do
          if selected
            li_ class: [('active' if with_errors), ('has-error' if with_errors)].compact do
              a_ href: "#tab_#{association_id}_0", data: { toggle: 'tab' } do
                model.with(object: selected).object_label
              end
            end
          end
        end,
      ]),
      div_('.tab-content', class: ('soft_hidden' unless opened)) do
        if !selected
          template_object = object.send("build_#{name}")
          form.fields_for name, template_object do |f|
            h_(
              f.link_to_remove(name) do
                f.span_ ".btn.btn-sm.btn-default", f.i_('.fa.fa-trash-o')
              end,
              f.generate(section: :nested, model: associated_model, nested_in: self)
            )
          end
        else
          div_ "#tab_#{association_id}_0.tab-pane.fade#{'.active.in' if with_errors}" do
            form.fields_for name, selected do |f|
              h_(
                if (is_template = f.options[:nested_form_template] || selected.new_record?) || can_destroy
                  f.link_to_remove name do
                    f.span_ ".btn.btn-sm.btn-#{is_template ? 'default' : 'danger'}", f.i_('.fa.fa-trash-o')
                  end
                end,
                f.generate(section: :nested, model: associated_model, nested_in: self)
              )
            end
          end
        end
      end
    ])
  end

  def render_filtering
    collection, selected_id, new_params, edit_params, abstract_model, config = filtering_options
    field_id = form.dom_id(self)
    h_(
      div_('.input-group') do
        form.select(method_name, collection, { include_blank: include_blank?, selected: selected_id },
          html_attributes.reverse_merge(
            class: ['form-control', 'js_field_input', ('js_modal_form_editable' if edit_params)],
            data: { element: 'select_remote', config: config }
          )
        )
      end,
      ul_('.list-inline', [
        if new_params
          li_ '.icon', title: wording_for(:link, :new, abstract_model) do
            a_ ".js_modal_form_new.btn.btn-default.btn-sm", i_('.fa.fa-plus'),
              href: '#',
              data: { new: { params: new_params, select_id: field_id } }
          end
        end,
        if edit_params
          li_ '.icon', title: wording_for(:link, :edit, abstract_model) do
            a_ "#js_modal_form_editable_#{field_id}.js_modal_form_edit.btn.btn-default.btn-sm", i_('.fa.fa-pencil'),
              href: '#',
              class: ('disabled' unless value),
              data: { edit: { params: edit_params, select_id: field_id } }
          end
        end
      ])
    )
  end

  def filtering_options
    model = associated_model
    abstract_model = model.abstract_model

    if (selected = selected_object(abstract_model))
      selected_id = selected.send(associated_primary_key)
      selected_name = model.with(object: selected).object_label
    else
      selected_id = self.selected_id
      selected_name = formatted_value
    end

    modal = request.variant.modal?

    if authorized?(:edit, abstract_model) && inline_edit && !modal
      edit_params = { model_name: abstract_model.to_param, modal: true }
    end

    config = {
      index_params: {
        model_name: abstract_model.to_param,
        compact: true
      },
      required: required?,
      include_blank: include_blank?,
      selected: [selected_id].compact, # TODO revise api
      values: [selected_id].compact,
      texts: [selected_name].compact,
    }

    if !form.object.new_record? && authorized?(:new, abstract_model) && inline_add && !modal
      new_params = { model_name: abstract_model.to_param, modal: true }
      new_params.merge!(associations: { inverse_of => (form.object.persisted? ? form.object.id : 'new') }) if inverse_of
    end

    selected_id = (fdv = form_default_value).nil? ? selected_id : fdv
    collection = selected_id ? [[selected_name, selected_id]] : []

    [collection, selected_id, new_params, edit_params, abstract_model, config]
  end

  def selected_object(abstract_model)
    related_id = params.dig(:associations, name)

    if form.object.new_record? && related_id.present? && related_id != 'new'
      abstract_model.get(related_id)
    end
  end
end
