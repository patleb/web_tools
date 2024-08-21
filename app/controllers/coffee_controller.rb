class CoffeeController < LibController
  def basic_template
  end

  def sign_in
    redirect_to '/coffee' unless request.get?
  end

  def company
    redirect_to '/coffee/error' unless request.get?
  end

  def error
    render_404
  end
end
