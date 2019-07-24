module ActionPresenter
  class TestCase < ActionController::TestCase
    attr_reader :view

    let(:presenter_class){ base_name.constantize }
    let(:presenter) do
      Current.view.assign(controller.view_assigns)
      presenter_class.new(locals)
    end
    let(:locals){ {} }

    before do
      Current.view = @view = controller.view_context
    end

    def reset_presenter
      reset_controller
      @_memoized.delete('presenter')
      @_memoized.delete('locals')
      Current.view = @view = controller.view_context
    end
  end
end
