module Rpc
  class FunctionsController < ActionController::API
    include ActionController::RequestForgeryProtection

    protect_from_forgery with: :exception

    def call
      function.call! params: params[:rpc_function].to_unsafe_h
      render json: function.result
    rescue ActiveRecord::RecordInvalid
      log Rpc::FunctionError.new(function)
      render json: function.error_hash, status: :not_acceptable
    rescue ActiveRecord::RecordNotFound
      head :not_found
    end

    private

    def function
      @function ||= Rpc::Function.find(params[:id])
    end
  end
end
