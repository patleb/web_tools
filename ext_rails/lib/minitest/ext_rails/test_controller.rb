module ExtRails
  class TestController < ActionController::Base
    def show
      public_send("test_#{params[:name]}")
    end
  end
end
