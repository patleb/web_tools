module Admin
  module Sections
    module Index::Paginate
      extend ActiveSupport::Concern

      included do
        register_option :paginate?, memoize: true do
          true
        end

        register_option :items_per_page, memoize: true do
          MixAdmin.config.items_per_page
        end

        register_option :shortcuts, memoize: true do
          MixAdmin.config.shortcuts
        end

        register_option :countless?, memoize: true do
          false
        end
      end

      def pagination
        total, estimate = total_count
        count = current_count
        count = total if count > total
        div_('.paginate.btn-group', pagination_links << span_('.badge', [
          count, t('admin.misc.of'), (ascii(:approx) if estimate), total, t('admin.misc.records')
        ]))
      end

      private

      def pagination_links
        return unless paginate?
        links = if countless?
          if current_page == 1 && presenters.empty?
            [page_tag(1)]
          else
            case current_page
            when 1 then next_page ? [1, 2, nil, nil, nil] : [1]
            when 2 then next_page ? [1, 2, 3,   nil, nil] : [1, 2]
            else next_page ? [1, nil, current_page, current_page + 1, nil] : [1, nil, current_page]
            end.map{ |page| page ? page_tag(page) : gap_tag }
          end
        else
          pages = available_pages.map{ |page| page_tag(page) }
          [prev_page_tag] + insert_gaps(pages)
        end
        links << next_page_tag
        links
      end

      def prev_page_tag
        a_('.btn.btn-xs', ascii(:arrow_left_x2), href: prev_url, rel: 'prev', disabled: !prev_page)
      end

      def next_page_tag
        a_('.btn.btn-xs', ascii(:arrow_right_x2), href: next_url, rel: 'next', disabled: !next_page)
      end

      def page_tag(page)
        case current_page
        when page     then a_('.btn.btn-sm.btn-active.pointer-events-none', page)
        when page - 1 then a_('.btn.btn-xs', page, href: next_url, rel: 'next')
        when page + 1 then a_('.btn.btn-xs', page, href: prev_url, rel: 'prev')
        else               a_('.btn.btn-xs', page, href: page_url(page))
        end
      end

      def gap_tag
        a_('.btn.btn-xs', ascii(:ellipsis), disabled: true)
      end

      def prev_url
        page_url(prev_page) if prev_page
      end

      def next_url
        page_url(next_page) if next_page
      end

      def page_url(page)
        params = page == 1 ? search_params : search_params.merge(p: page)
        model.url_for(action.name, **params)
      end

      def total_count
        if countless?
          estimate, total = paginator.recordset.records.count_estimate, current_count
          if !next_page
            exact = true
          elsif estimate <= total
            total = total + Array.wrap(items_per_page).last
          else
            total = estimate
          end
          [total, !exact]
        else
          [paginator.recordset.records_count, false]
        end
      end

      def current_count
        memoize(self, __method__, bindings) do
          page, page_i = current_page, 1
          items = Array.wrap(items_per_page)
          total = items.reduce(0) do |total, per_page|
            break total if page == page_i
            page_i += 1
            total + per_page
          end
          total += (page - page_i) * items.last if page > page_i
          total + presenters.size
        end
      end

      def current_page
        paginator.number
      end

      def prev_page
        current_page - 1 unless paginator.first?
      end

      def next_page
        paginator.next_param unless presenters.empty? || paginator.last?
      end

      def available_pages
        memoize(self, __method__, bindings) do
          total_pages = paginator.recordset.page_count
          left, window, right = shortcuts.values_at(:left, :window, :right)
          left = [*1..left + 1]
          right = [*total_pages - right..total_pages]
          window = [*current_page - window - 1..current_page + window + 1]
          (left | window | right).sort.reject{ |x| (x < 1) || (x > total_pages) }
        end
      end

      def insert_gaps(pages)
        if (total_pages = paginator.recordset.page_count) > (pages_size = pages.size)
          page_at = 1
          gaps_at = available_pages.each_with_object([]).with_index do |(page, memo), i|
            gap = page > page_at + 1
            page_at = page
            memo << i if gap
          end
          gaps = case
            when total_pages <= max_shortcuts     then total_pages   - pages_size
            when total_pages == max_shortcuts + 1 then max_shortcuts - pages_size + 1
            else                                       max_shortcuts - pages_size + 2
            end
          if gaps_at.size == 2
            left_gaps = gaps / 2
            pages.insert(gaps_at.first, [gap_tag] * left_gaps)
            right_gaps = gaps - left_gaps
            pages.insert(gaps_at.last + left_gaps, [gap_tag] * right_gaps)
          else
            pages.insert(gaps_at.first, [gap_tag] * gaps)
          end
        end
        pages
      end

      def max_shortcuts
        @max_shortcuts ||= begin
          left, window, right = shortcuts.values_at(:left, :window, :right)
          # first + left + window + prev + current + next + window + right + last
          5 + left + window * 2 + right
        end
      end
    end
  end
end
