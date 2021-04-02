module Rpc
  class FunctionsController < ActionController::API
    include ActionController::RequestForgeryProtection

    protect_from_forgery with: :exception

    def call
      function.update! params: call_params
      render json: function.result
    rescue ActiveRecord::RecordInvalid
      render json: { flash: { error: function.errors.full_messages } }, status: :not_acceptable
    rescue ActiveRecord::RecordNotFound
      head :not_found
    end

    private

    def call_params
      params[:rpc_function].permit(*function.permitted_attributes)
    end

    def function
      @function ||= Rpc::Function.find(params[:id])
    end
  end
end
