module Rpc
  class FunctionsController < ActionController::API
    include ActionController::RequestForgeryProtection

    protect_from_forgery with: :exception

    def call
      function.update! params: params[:rpc_function].to_unsafe_h
      render json: function.result
    rescue ActiveRecord::RecordInvalid
      render json: { error: function.errors.full_messages.first }, status: :not_acceptable
    rescue ActiveRecord::RecordNotFound
      head :not_found
    end

    private

    def function
      @function ||= Rpc::Function.find(params[:id])
    end
  end
end
