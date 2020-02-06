module ActionController::Base::BeforeRenderInstance
  def render(*args, &blk)
    run_callbacks :render do
      super
    end
  end
end
