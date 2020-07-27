module RailsAdmin
  class ModelNotFound < ::StandardError; end
  class ObjectNotFound < ::StandardError; end
  class TooManyRows < ::StandardError; end

  module Main::WithErrors
    extend ActiveSupport::Concern

    included do
      rescue_from Pundit::NotAuthorizedError, with: :on_not_authorized_error
      rescue_from ObjectNotFound, with: :on_object_not_found
      rescue_from ModelNotFound, with: :on_model_not_found
      rescue_from ActiveRecord::InvalidForeignKey, with: :on_invalid_foreign_key
      rescue_from ActiveRecord::StaleObjectError, with: :on_stale_object_error
      rescue_from ActiveRecord::NestedAttributes::TooManyRecords, with: :on_too_many_records # TODO restrict client side
      rescue_from TooManyRows, with: :on_too_many_rows
    end

    def on_not_authorized_error(_)
      flash[:error] = I18n.t('admin.flash.not_allowed')
      redirect_to(main_app.try(:root_path) || '/')
    end

    def on_object_not_found(_)
      flash[:error] = I18n.t('admin.flash.object_not_found', model: @model_name, id: params[:id])
      redirect_to_index
    end

    def on_model_not_found(_)
      unless defined?(MrUser) && @model_name == 'Users'
        flash[:error] = I18n.t('admin.flash.model_not_found', model: @model_name)
      end
      redirect_to root_path
    end

    def on_invalid_foreign_key(_)
      (@object || @objects.first).errors.add :base, :dependency_constraints
      handle_save_error action_name
    end

    def on_stale_object_error(_)
      @object.errors.add :base, :already_modified_html
      @object.lock_version = @object.lock_version_was
      handle_save_error :edit
    end

    def on_too_many_records(exception)
      @object.errors.add :base, exception.message
      handle_save_error action_name
    end

    def on_too_many_rows(exception)
      if export_action?
        flash[:error] = exception.message
        redirect_to_back
      else
        response.headers['X-Status-Reason'] = exception.message
        head 413
      end
    end
  end
end
