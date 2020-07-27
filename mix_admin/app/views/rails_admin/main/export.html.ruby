path_params = params.permit(:model_name, :scope, :query, :sort, :reverse, bulk_ids: [], f: {}).merge(all: true)
guessed_encoding = @abstract_model.klass.encoding
encoding_options = options_for_select(Encoding.name_list.sort, guessed_encoding)
separator_options = options_for_select({ "comma ,": ',', "semicolon ;": ';', 'tabs': "'\t'" }, ',')
export_fields = main_fields.select(&:export_visible?)

h_(
  @p.filter_box.render,
  form_tag(export_path(path_params.with_keyword_access), method: 'post', class: 'form-horizontal') {[
    input_(name: "file", type: "hidden", value: "true"),
    fieldset_('#js_export_fields', [
      legend_('.js_main_panel', [
        i_('.fa.fa-chevron-down'),
        t('admin.export.select')
      ]),
      div_('.form-group.control-group') do
        div_ '.col-sm-12' do
          div_ '.checkbox' do
            label_({ for: 'js_export_check_all' }, [
              check_box_tag('all', 'all', true, id: 'js_export_check_all'),
              b_{ t('admin.export.select_all_fields') }
            ])
          end
        end
      end,
      div_('.form-group.control-group') do
        div_('.col-sm-12', [
          div_('.js_export_select_all.well.well-sm', title: t('admin.export.click_to_reverse_selection')) do
            b_{ t('admin.export.fields_from', name: @model.label_plural.downcase) }
          end,
          div_('.controls') do
            div_('.row') do
              export_fields.select{ |f| !f.association? || f.polymorphic? }.map do |field|
                list = field.virtual? ? 'methods' : 'only'
                div_ '.checkbox.col-sm-3' do
                  if field.association? && field.polymorphic?
                    [
                      label_({ for: "schema_#{list}_#{field.method_name}" }, [
                        check_box_tag("schema[#{list}][]", field.method_name, true, id: "schema_#{list}_#{field.method_name}"),
                        "#{field.label} [id]"
                      ]),
                      label_({ for: "schema_#{list}_#{polymorphic_type_column_name = @abstract_model.columns.find{ |c| field.property.foreign_type == c.name }.name}" }, [
                        check_box_tag("schema[#{list}][]", polymorphic_type_column_name, true, id: "schema_#{list}_#{polymorphic_type_column_name}"),
                        "#{field.label.upcase_first} [type]"
                      ])
                    ]
                  else
                    label_({ for: "schema_#{list}_#{field.name}" }, [
                      check_box_tag("schema[#{list}][]", field.name, true, id: "schema_#{list}_#{field.name}"),
                      field.label.upcase_first
                    ])
                  end
                end
              end
            end
          end
        ])
      end,
      export_fields.select{ |f| f.association? && !f.polymorphic? }.map do |field|
        div_ '.form-group.control-group' do
          div_('.col-sm-12', [
            div_('.js_export_select_all.well.well-sm', title: t('admin.export.click_to_reverse_selection')) do
              b_{ t('admin.export.fields_from_associated', name: field.label.downcase) }
            end,
            div_('.controls') do
              div_ '.row' do
                field.associated_model.export.visible_fields.reject(&:association?).map do |associated_model_field|
                  list = associated_model_field.virtual? ? 'methods' : 'only'
                  div_ '.checkbox.col-sm-3' do
                    label_({ for: "schema_include_#{field.name}_#{list}_#{associated_model_field.name}" }, [
                      check_box_tag("schema[include][#{field.name}][#{list}][]", associated_model_field.name, true, id: "schema_include_#{field.name}_#{list}_#{associated_model_field.name}"),
                      associated_model_field.label.upcase_first
                    ])
                  end
                end
              end
            end
          ])
        end
      end
    ]),
    fieldset_([
      legend_('.js_main_panel', [
        i_('.fa.fa-chevron-down'),
        t('admin.export.options_for', name: 'csv')
      ]),
      div_('.form-group.control-group', [
        label_('.col-sm-2.control-label', t('admin.export.csv.encoding_to'), for: "csv_options_encoding_to"),
        div_('.col-sm-4.controls', [
          select_tag('csv_options[encoding_to]', encoding_options, required: true, class: 'form-control'),
          p_('.help-block', t('admin.export.csv.encoding_to_help', name: guessed_encoding))
        ])
      ]),
      div_('.form-group.control-group', [
        label_('.col-sm-2.control-label', t('admin.export.csv.skip_header'), for: "csv_options_skip_header"),
        div_('.col-sm-10.controls', [
          div_('.checkbox') do
            label_ '.export_skip_header_label' do
              check_box_tag 'csv_options[skip_header]', 'true'
            end
          end,
          p_('.help-block', t('admin.export.csv.skip_header_help'))
        ])
      ]),
      div_('.form-group.control-group', [
        label_('.col-sm-2.control-label', t('admin.export.csv.col_sep'), for: "csv_options_generator_col_sep"),
        div_('.col-sm-4.controls') do
          select_tag 'csv_options[generator][col_sep]', separator_options, class: 'form-control', required: true
        end
      ])
    ]),
    div_('.form-group.form-actions') do
      div_('.col-sm-offset-2.col-sm-10', [
        button_('.btn.btn-primary', { class: bs_form_row, type: "submit", name: 'csv' }, [
          i_('.fa.fa-check.icon-white'),
          t("admin.export.confirmation", name: 'csv') # TODO button should be disabled?
        ]),
        main_section.extra_formats.map do |format|
          button_ '.btn.btn-info', class: bs_form_row, type: "submit", name: format do
            t("admin.export.confirmation", name: format)
          end
        end,
        button_('.btn', { class: bs_form_row, type: "submit", name: "_cancel", formnovalidate: true, data: { remote: true } }, [
          i_('.fa.fa-times'),
          t("admin.form.cancel")
        ])
      ])
    end
  ]}
)
