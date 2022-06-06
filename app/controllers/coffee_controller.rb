class CoffeeController < ActionController::Base
  def basic_template
    render :basic_template
  end

  def sign_in
    if request.get?
      render :sign_in
    else
      redirect_to '/coffee'
    end
  end

  def company
    if request.get?
      render :company
    else
      redirect_to '/coffee/error'
    end
  end

  def error
    render_404
  end
end
