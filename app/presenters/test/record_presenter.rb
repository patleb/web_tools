module Test
  class RecordPresenter < ActionView::Delegator
    delegate :[], to: :record
  end
end
