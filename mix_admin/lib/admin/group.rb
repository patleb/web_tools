# frozen_string_literal: true

module Admin
  class Group < ActionView::Delegator
    include Configurable

    attr_accessor :weight

    delegate :field!, :field, to: :model
    delegate :fields_of_type, :include_fields, :exclude_fields, to: :section

    register_option :allowed? do
      true
    end

    register_option :open? do
      true
    end

    register_option :css_class do
      "#{name}_group"
    end

    register_option :label do
      name == :default ? presenter.record_label : name.to_s.humanize
    end

    register_option :help do
      nil
    end

    def parent
      return @parent if defined? @parent
      parent = section.parent
      @parent = parent && parent.weight < section_was.weight ? parent.groups_hash[name] : nil
    end

    def fieldset
      return if (group_fields = fields).empty?
      group_label = label
      fields, hidden_fields = group_fields.partition(&:label)
      fieldset_('.group_fields', class: css_class) {[
        hidden_fields.map(&:pretty_input),
        legend_('.group', if: group_label) {[
          h6_('.group_label') { group_label },
          p_('.group_help', if: help) { help },
        ]},
        dl_('.fields') do
          fields.map do |field|
            div_('.field', id: "#{field.name}_field") {[
              dt_('.field_label') do
                field.pretty_label
              end,
              dd_('.field_value', class: field.css_class) do
                field.pretty_input
              end,
            ]}
          end
        end
      ]}
    end

    def fields
      fields_hash.values
    end

    def fields_hash
      memoize(self, __method__, bindings) do
        allowed ? section.with(bindings).fields_hash.select{ |_, f| f.group.name == name } : {}
      end
    end
  end
end
