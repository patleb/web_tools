module Admin
  module Field::AsAssociation
    extend ActiveSupport::Concern

    prepended do
      delegate :foreign_key, :foreign_type, :polymorphic?, :list_parent?, :inverse_of, :nested_options, to: :property

      register_option :open? do
        true
      end

      register_option :pretty_value do
        pretty_association(value).join(pretty_separator).html_safe
      end

      register_option :pretty_separator do
        '<br>'.html_safe
      end

      register_option :sanitized? do
        false
      end

      register_option :queryable do
        if associated_model.columns_hash.has_key? associated_model.record_label_method
          associated_model.record_label_method
        else
          method_name
        end
      end

      register_option :eager_load do
        name
      end

      register_option :left_joins do
        false
      end

      register_option :distinct? do
        false
      end

      register_option :include_blank? do
        true
      end
    end

    def allowed_field?
      super && associated_model.allowed?
    end

    def pretty_association(value)
      return [pretty_blank] unless value.present?
      value.map do |presenter|
        label = format_value(presenter).presence || pretty_blank
        label = sanitize(label) if sanitized?
        if presenter.discarded? || !(url = presenter.viewable_url)
          label
        else
          a_('.link.text-primary', text: label, href: url)
        end
      end
    end

    def associated_model
      @associated_model ||= property.klass.admin_model
    end

    def multiple?
      false
    end

    def method?
      true
    end

    def format_value(value)
      value.record_label
    end

    def value
      memoize(self, __method__, bindings) do
        records.select_map do |association|
          next unless (presenter = association.admin_presenter).allowed?
          presenter
        end
      end
    end

    private

    def records
      Array.wrap(presenter[property.name])
    end
  end
end
