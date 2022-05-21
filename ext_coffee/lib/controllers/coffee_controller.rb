class CoffeeController < ActionController::Base
  def index
  end

  def create
    # TODO or render with errors
    redirect_to '/coffee', turbolinks: true
  end
end
