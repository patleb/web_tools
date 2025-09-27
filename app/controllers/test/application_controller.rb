module Test
  class ApplicationController < ApplicationController
    layout 'application'

    def home
    end

    def error
      raise 'error'
    end
  end
end
