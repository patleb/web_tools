module Pages
  class PaginationPresenter < ActionView::Delegator[:@page]
    def self.render
      new.render
    end

    def render
      div_('.pagination') do
        [prev_page, next_page].compact.join(' | ').html_safe
      end
    end

    private

    def prev_page
      prev_page_presenter&.render(class: ['prev_page']) {[
        i_('.fa.fa-chevron-circle-left'),
        span_{ t('page_paginate.prev') }
      ]}
    end

    def next_page
      next_page_presenter&.render(class: ['next_page']) {[
        span_{ t('page_paginate.next') },
        i_('.fa.fa-chevron-circle-right')
      ]}
    end

    def prev_page_presenter
      with_layout_links do |links, index|
        links[index - 1] if index && index > 0
      end
    end

    def next_page_presenter
      with_layout_links do |links, index|
        links[index + 1] if index && index < links.size - 1
      end
    end

    def with_layout_links
      links = layout_link_presenters(:sidebar)&.list || []
      index = links.index{ |presenter| presenter.record.fieldable_id == @page.id }
      yield(links, index)
    end
  end
end
