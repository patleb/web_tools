module Test::Records
  class IndexPresenter < ActionView::Delegator[:@presenters]
    def columns
      %i(id boolean datetime decimal integer string text)
    end
  end
end
