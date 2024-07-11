require 'geared_pagination/recordset'
require 'geared_pagination/headers'

module GearedPagination
  module Controller
    extend ActiveSupport::Concern

    included do
      after_action :set_paginated_headers, if: :geared_page?
      etag { @paginator if geared_page? }
      attr_reader :paginator
      helper_method :paginator
    end

    def set_page_and_extract_portion_from(records, ordered_by: nil, per_page: nil)
      @paginator = current_page_from(records, ordered_by: ordered_by, per_page: per_page)
      @paginator.records
    end

    private

    def current_page_from(records, ordered_by: nil, per_page: nil)
      GearedPagination::Recordset.new(records, ordered_by: ordered_by, per_page: per_page).page(current_page_param)
    end

    def set_paginated_headers
      GearedPagination::Headers.new(page: @paginator, controller: self).apply
    end

    def geared_page?
      @paginator.is_a? GearedPagination::Page
    end

    def current_page_param
      params[:p]
    end
  end
end

ActionController::Base.include GearedPagination::Controller
