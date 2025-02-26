module Admin
  module Sections
    class Delete < Admin::Section
      def render
        bulk = presenter.nil?
        can_delete = false
        form_('.delete_records', action: (presenter || model).url, remote: true, back: true) {[
          legend_(t('admin.form.bulk_delete')),
          presenters.map do |presenter|
            label = presenter.record_label
            allowed, restricted = model.associated_counts(presenter).values_at(:allowed, :restricted)
            can_destroy = allowed.values.all?(&:last) && restricted.values.all?(&:last)
            can_delete ||= can_destroy
            fieldset_{[
              input_(name: 'ids', value: presenter.primary_key_value, type: 'hidden', multiple: true, if: bulk && can_destroy),
              span_([
                a_('.link', [label, (t('admin.form.cant_delete') unless can_destroy)],
                  class: { 'link-primary' => can_destroy, 'link-error' => !can_destroy },
                  href: presenter.viewable_url,
                  if: presenter.viewable?
                ) || label
              ]),
              ul_(if: allowed.present? || restricted.present?) {[
                allowed.map do |klass, (count, url, _can_destroy)|
                  li_([
                    span_(ascii_(:arrow_down_right)),
                    a_('.link.link-primary', count_label(klass, count), href: url),
                  ])
                end,
                restricted.map do |klass, (count, _can_destroy)|
                  li_ [ascii_(:arrow_down_right), count_label(klass, count)]
                end,
              ]}
            ]}
          end,
          buttons(
            trash: can_delete && presenters.first.allowed?(:trash) && t('admin.form.trash'),
            delete: can_delete && model.allowed?(:delete) && t('admin.form.delete'),
            cancel: t('admin.form.cancel'),
          ),
        ]}
      end

      private

      def count_label(klass, count)
        [(ascii_(:approx) if count.is_a? BigDecimal), count.to_i, klass.admin_label(count)]
      end
    end
  end
end
