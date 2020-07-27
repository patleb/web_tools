append :contextual_tabs do
  @p.filter_box.menu
end

h_(
  div_('#js_chart_init', data: { init: @p.ordered_charts }),
  @p.filter_box.render,
  form_tag(@p.chart_form_path, method: :post, class: 'form-horizontal js_chart_form', remote: true) {[
    input_(name: "chart", type: "hidden", value: "true"),
    @p.render,
    fieldset_([
      div_('.form-group.control-group', [
        label_('.col-sm-2.control-label', t('admin.chart.field'), for: "chart_form_field"),
        div_('.col-sm-4.controls') do
          select_tag 'chart_form[field]', @p.field_options, class: 'form-control js_chart_inputs', required: true
        end
      ]),
      div_('.form-group.control-group', [
        label_('.col-sm-2.control-label', t('admin.chart.calculation'), for: "chart_form_calculation"),
        div_('.col-sm-4.controls') do
          select_tag 'chart_form[calculation]', @p.calculation_options, class: 'form-control js_chart_inputs', required: true
        end
      ]),
      if @p.refresh_rate
        div_('.form-group.control-group', [
          label_('.col-sm-2.control-label', t('admin.chart.auto_refresh', rate: @p.refresh_rate), for: "chart_form_auto_refresh"),
          div_('.col-sm-10.controls') do
            div '.checkbox' do
              label_ '.chart_form_auto_refresh_label' do
                check_box_tag 'chart_form[auto_refresh]', 'true', @p.auto_refresh_default
              end
            end
          end
        ])
      end
    ]),
    fieldset_ do
      div_ '.well.js_chart_added_list'
    end,
    fieldset_ do
      @p.choose.render
    end,
    div_('.form-group.form-actions') do
      div_('.col-sm-offset-2.col-sm-10', [
        button_('.js_chart_submit_button.btn.btn-primary', { class: bs_form_row, type: "submit", name: 'chart', formnovalidate: true }, [
          i_('.fa.fa-refresh.icon-white'),
          t('admin.misc.refresh')
        ]),
        button_('.js_chart_add_link.btn.btn-info', { class: bs_form_row, type: 'button' }, [
          i_('.fa.fa-plus.icon-white'),
          t("admin.chart.add")
        ]),
        button_('.btn', { class: bs_form_row, type: "submit", name: "_cancel", formnovalidate: true }, [
          i_('.fa.fa-times'),
          t("admin.form.cancel")
        ])
      ])
    end
  ]}
)
