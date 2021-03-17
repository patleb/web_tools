module ActionController::Base::BeforeRenderInstance
  def render(...)
    run_callbacks :render do
      super
    end
  end
end
