module Admin
  module Sections
    class Show < Admin::Section
      register_option :memoize_scroll_items? do
        true
      end

      def after_initialize
        super
        @scroll_items ||= {}
      end

      def render
        groups.html_map do |group|
          group.fieldset
        end
      end

      def scroll_items
        if memoize_scroll_items?
          (@scroll_items[Current.locale] ||= {})[Current.user.as_role] ||= super + _scroll_items
        else
          super + _scroll_items
        end
      end

      private

      def _scroll_items
        [li_('.menu_divider')] + groups.flat_map(&:fields).select_map do |field|
          next unless (label = field.label)
          li_(a_ [ascii_(:arrow_right), label], href: "##{field.name}_field", 'data-turbolinks-history': false)
        end
      end
    end
  end
end
