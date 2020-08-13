module ActionController
  # TODO https://github.com/rails/rails/pull/31129
  # TODO https://github.com/rails/rails/pull/31235/files
  class DbTimeout < ActiveRecord::StatementInvalid
    def self.===(exception)
      exception.message =~ /PG::QueryCanceled/
    end
  end

  module WithErrors
    extend ActiveSupport::Concern

    KEEP_CALLBACK_ACTIONS = [:set_current, :with_context]
    SKIP_CALLBACK_ACTIONS = ActionController::WithStatus.public_instance_methods

    included do
      _process_action_callbacks.each do |callback|
        next if (name = callback.filter).in? KEEP_CALLBACK_ACTIONS
        __send__ "skip_#{callback.kind}_action", name, only: SKIP_CALLBACK_ACTIONS
      end

      # TODO rack https://github.com/rails/rails/pull/23868/files
      rescue_from Exception, with: :render_500 if MixRescue.config.rescue_500
      rescue_from DbTimeout, with: :render_408
    end
  end
end
