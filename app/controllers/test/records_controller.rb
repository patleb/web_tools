module Test
  class RecordsController < ApplicationController
    def index
      @presenters = Test::Record.all.map{ |record| Test::RecordPresenter.new(record: record) }
      @template = Test::Records::IndexPresenter.new
    end
  end
end
