class PicoController < LibController
  def basic_template
  end

  def sign_in
    redirect_to '/pico' unless request.get?
  end

  def company
    redirect_to '/pico/error' unless request.get?
  end

  def error
    render_404
  end
end
