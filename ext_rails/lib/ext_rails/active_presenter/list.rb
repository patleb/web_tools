module ActivePresenter
  class List < ActionView::Delegator
    attr_reader :list

    def initialize(list:, **)
      @list = list
      super(**)
    end

    def after_initialize
      super
      list.each{ |presenter| presenter.list = self }
    end
  end
end
