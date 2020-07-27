module RailsAdmin::Main
  class PaginatePresenter < ActionPresenter::Base[:@model, :@objects]
    PARAMS = %i(page per more first).freeze

    delegate :current_page, :next_page, :prev_page, :total_pages, :total_count, :limit_value, :offset_value, :size, to: :@objects

    def render
      if (limited = index_section.limited_pagination?) # TODO no count at all for APIs --> or use total_pages == 0
        total, estimate = total_estimate
      else
        total = total_count
      end
      h_(
        paginate_tag('more', [
          li_('.js_paginate_link', data: { url: next_url(more: first_more) }, class: ('js_disable' unless next_page)) do
            a_ '.btn.btn-default', t('admin.concepts.paginate.more'), href: '#'
          end,
          li_('.paginate_total', class: ('js_table_all_loaded' if !estimate && current_count == total)) do
            span_("#{current_count} / #{'~' if estimate}#{total} #{@model.pluralize(total).downcase}")
          end,
          div_('.js_table_scroll_up.fa.fa-angle-double-up')
        ]),
        paginate_tag('page', [
          prev_page_tag,
          (limited ? pages_without_count_tag : pages_with_count_tag),
          next_page_tag,
        ]),
        paginate_tag('per', [
          div_('.input-group', [
            span_('.input-group-addon', t('admin.concepts.paginate.per')),
            select_tag('js_paginate_max', options_for_select(per_choices, per_default), class: 'form-control')
          ])
        ]),
      )
    end

    private

    def paginate_tag(type, tags)
      div_ '.row.paginate' do
        div_ '.col' do
          ul_ ".pagination.paginate_#{type}", tags
        end
      end
    end

    def total_estimate
      if !next_page
        exact = true
        total = current_total
      elsif count_estimate <= current_total
        total = current_total + limit_value
      else
        total = count_estimate
      end
      [total, !exact]
    end

    def count_estimate
      @_count_estimate ||= @objects.count_estimate.ceil_to(limit_value)
    end

    def current_count
      @_current_count ||= params[:more] ? (offset_value + size - (first_more - 1) * limit_value) : size
    end

    def current_total
      @_current_total ||= prev_page ? (size + prev_page * limit_value) : size
    end

    def first_more
      (params[:more] || current_page).to_i
    end

    def prev_page_tag
      li_(class: ('js_disable' unless prev_page)) do
        a_ '.btn.btn-default.pjax', i_('.fa.fa-angle-left'), href: prev_url, rel: ('prev' if prev_page), data: { disable: :click }
      end
    end

    def next_page_tag
      li_(class: ('js_disable' unless next_page)) do
        a_ '.btn.btn-default.pjax', i_('.fa.fa-angle-right'), href: next_url, rel: ('next' if next_page), data: { disable: :click }
      end
    end

    def pages_with_count_tag
      pages = paginator_pages.map{ |page| page_tag(page) }
      insert_gaps(pages)
    end

    def pages_without_count_tag
      if current_page > 1 && @objects.out_of_range?
        return [out_of_range_tag].concat([gap_tag] * 4)
      end
      case current_page
      when 1 then [(1 if size > 0), (2 if next_page), nil,              nil,              nil]
      when 2 then [1,               2,                (3 if next_page), nil,              nil]
      when 3 then [1,               2,                3,                (4 if next_page), nil]
      else        [1,               nil,              prev_page,        current_page,     next_page]
      end.map{ |page| page ? page_tag(page) : gap_tag }
    end

    def page_tag(page)
      case current_page
      when page     then current = 'paginate_current'
      when page - 1 then rel = 'prev'
      when page + 1 then rel = 'next'
      end
      li_(class: ('js_disable' if current)) do
        a_ '.btn.btn-default.pjax', page, class: current, href: (page_url(page) unless current), rel: rel, data: { disable: :click }
      end
    end

    def out_of_range_tag
      li_ do
        a_ '.btn.btn-default.pjax', 1, href: page_url(1), data: { disable: :click }
      end
    end

    def gap_tag
      li_(class: 'js_disable') do
        a_ '.btn.btn-default', "…"
      end
    end

    def next_url(**params)
      page_url(next_page, **params) if next_page
    end

    def prev_url(**params)
      page_url(prev_page, **params) if prev_page
    end

    def page_url(page, **params)
      unless page == 1
        params[:page]  = page
        params[:first] = first_item unless first_item.nil?
      end
      params.any? ? "#{base_url}&#{params.to_query}" : base_url
    end

    def base_url
      @_base_url ||= begin
        path_params = params.with_keyword_access.except(*PARAMS).merge(sort: sort, reverse: reverse)
        index_section.abstract_model.url_for(main_action, **path_params)
      end
    end

    def first_item
      return @_first_item if defined? @_first_item
      @_first_item =
        if index_section.sort_paginate.exclude? sort.to_sym
          nil
        elsif current_page == 1
          if (value = @objects.first.try(sort)).respond_to? :utc
            value = value.utc.iso8601
          end
          value
        else
          params[:first]
        end
    end

    def insert_gaps(pages)
      if total_pages > (pages_size = pages.size)
        page_at = 1
        gaps_at = paginator_pages.each_with_object([]).with_index do |(page, memo), i|
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
      # first + left + window + prev + current + next + window + right + last
      @_max_shortcuts ||= 5 + paginator_options[:left] + paginator_options[:right] + paginator_options[:window] * 2
    end

    def paginator_pages
      @_paginator_pages ||= paginator.each_page.to_a
    end

    def paginator_options
      @_paginator_options ||= paginator.instance_variable_get(:@window_options)
    end

    def paginator
      @_paginator ||= Kaminari::Helpers::Paginator.new(Current.view, total_pages: total_pages, current_page: current_page, per_page: limit_value, remote: false)
    end

    def per_default
      per_choices.include?(paginate_per) ? paginate_per : per_choices.first
    end

    def per_choices
      @_per_choices ||= [index_section.items_per_page, index_section.max_items_per_page]
    end
  end
end
