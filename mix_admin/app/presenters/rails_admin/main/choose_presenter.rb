# TODO rename choose to pick
module RailsAdmin::Main
  class ChoosePresenter < ActionPresenter::Base[:@model, :@abstract_model]
    def render
      return unless main_section.choose?
      h_(
        div_('.form-group.control-group', [
          label_('.col-sm-2.control-label', t('admin.choose.saved'), for: "main_chosen"),
          div_('.col-sm-4.controls') do
            select_tag 'main[chosen]', chosen_options, include_blank: true, class: 'form-control js_choose_list'
          end
        ]),
        # TODO add authorization adapter
        div_('.form-group.form-actions') do
          div_('.col-sm-offset-2.col-sm-10', [
            div_(class: bs_form_row) do
              text_field_tag 'choose[label]', nil,
                placeholder: t('admin.choose.label'),
                class: 'form-control js_choose_label',
                required: true
            end,
            span_('.btn.btn-sm.btn-primary.js_choose_save', [
              i_('.fa.fa-check'),
              t('admin.form.save')
            ]),
            span_('.btn.btn-sm.btn-default.js_choose_delete', [
              i_('.fa.fa-trash-o'),
              t("admin.form.delete")
            ]),
            # TODO set as default --> user preferences
          ])
        end
      )
    end

    def chosen_options
      options_for_select(chooses.sort_by(&:first).each_with_object({}){ |(key, value), memo|
        memo[key.underscore.humanize] = value.to_json
      }, chosen_default)
    end

    def chosen_default
      params.dig(:main, :chosen)
    end

    def chooses
      @_chooses ||= RailsAdmin::Choose.group_by_label(
        section: main_action,
        model: @abstract_model.to_param,
        prefix: main_section.choose_prefix
      )
    end
  end
end
