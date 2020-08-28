module RailsAdmin
  class MainPresenter < ActionPresenter::Base[:@abstract_model]
    attr_reader :bulk, :paginate, :table

    def params
      @params ||= Current.controller.params
    end

    def filter_box
      @_filter_box ||= FilterBoxPresenter.new
    end

    def choose
      @_choose ||= ChoosePresenter.new
    end

    # TODO move into TablePresenter#after_initialize and define accessors like filter_box/choose --> params?
    def initialize_table_presenters
      params = Current.controller.params.permit(
        :model_name, :scope, :query, :sort, :reverse, *PaginatePresenter::PARAMS, f: {}
      )
      sort    = params[:sort]
      reverse = params.delete(:reverse).to_b
      params.delete(:query) if params[:query].blank?
      params.delete(:sort)  if sort == index_section.sort_by.to_s
      sort_hash = { sort: sort, reverse: reverse }

      @bulk     = BulkPresenter.new
      @paginate = PaginatePresenter.new(**sort_hash, params: params)
      @params   = params.except(*PaginatePresenter::PARAMS)
      @table    = TablePresenter.new(**sort_hash, params: @params, bulk: @bulk)
    end
  end
end
