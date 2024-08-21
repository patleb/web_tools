module Test
  class RecordsController < ApplicationController
    authenticate except: [:index]

    def index
      @presenters = Test::Record.all.map{ |record| Test::RecordPresenter.new(record: record) }
      @template = Test::Records::IndexPresenter.new
      flash.now[:notice] = "Table of #{@presenters.size} records"
    end
  end
end
