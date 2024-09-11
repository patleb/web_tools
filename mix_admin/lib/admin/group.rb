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
      name == :default ? "#{presenter.record_label}" : name.to_s.humanize
    end

    register_option :help, memoize: :locale do
      nil
    end

    def parent
      return @parent if defined? @parent
      parent = section.parent
      @parent = parent && parent.weight < section_was.weight ? parent.groups_hash[name] : nil
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
