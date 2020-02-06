module ActionController::Base::BeforeRender
  extend ActiveSupport::Concern
  include ActiveSupport::Callbacks

  included do
    define_callbacks :render,
      terminator: ->(controller, result_lambda) { result_lambda.call if result_lambda.is_a?(Proc); controller.performed? },
      skip_after_callbacks_if_terminated: true
  end

  module ClassMethods
    def append_before_render_filter(*names, &blk)
      _insert_callbacks(names, blk) do |name, options|
        set_callback(:render, :before, name, options)
      end
    end

    def prepend_before_render_filter(*names, &blk)
      _insert_callbacks(names, blk) do |name, options|
        set_callback(:render, :before, name, options.merge(:prepend => true))
      end
    end

    def skip_before_render_filter(*names, &blk)
      _insert_callbacks(names, blk) do |name, options|
        skip_callback(:render, :before, name, options)
      end
    end

    alias_method :before_render, :append_before_render_filter
    alias_method :append_before_render, :append_before_render_filter
    alias_method :prepend_before_render, :prepend_before_render_filter
    alias_method :skip_before_render, :skip_before_render_filter
  end
end
